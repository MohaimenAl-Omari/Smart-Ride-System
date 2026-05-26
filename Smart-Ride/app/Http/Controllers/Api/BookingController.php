<?php

namespace App\Http\Controllers\Api;

use Carbon\Carbon;
use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Trip;
use App\Models\TripSegment;
use App\Services\FcmService;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class BookingController extends Controller
{
    public function store(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'passenger') {
            return response()->json([
                'status'  => false,
                'message' => 'Only passengers can create bookings.',
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'trip_id'          => 'required|exists:trips,id',
            'seats'            => 'required|integer|min:1|max:6',
            'pickup_stop'      => 'nullable|string|max:120',
            'dropoff_stop'     => 'nullable|string|max:120',
            'pickup_lat'       => 'nullable|numeric|between:-90,90',
            'pickup_lng'       => 'nullable|numeric|between:-180,180',
            'pickup_address'   => 'nullable|string|max:300',
            'dropoff_lat'      => 'nullable|numeric|between:-90,90',
            'dropoff_lng'      => 'nullable|numeric|between:-180,180',
            'dropoff_address'  => 'nullable|string|max:300',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
            ], 400);
        }

        $trip = Trip::with(['stops', 'segments'])->findOrFail($request->trip_id);

        if ($trip->status !== 'scheduled') {
            return response()->json([
                'status'  => false,
                'message' => 'This trip is not available for booking.',
            ], 400);
        }

        if ($trip->driver_id === $user->id) {
            return response()->json([
                'status'  => false,
                'message' => 'You cannot book your own trip.',
            ], 400);
        }

        $exists = Booking::where('trip_id', $trip->id)
            ->where('passenger_id', $user->id)
            ->whereIn('status', ['pending', 'accepted'])
            ->exists();
        if ($exists) {
            return response()->json([
                'status'  => false,
                'message' => 'You already have an active booking on this trip.',
            ], 400);
        }

        $pickup  = $request->pickup_stop  ?? $trip->origin;
        $dropoff = $request->dropoff_stop ?? $trip->destination;
        $seats   = (int) $request->seats;

        // ── Segment-aware availability check ─────────────────────────
        $allSegs = $trip->segments()->orderBy('order_index')->get();
        if ($allSegs->isNotEmpty()) {
            $covered = $this->getSegmentsForRoute($allSegs, $pickup, $dropoff);
            foreach ($covered as $seg) {
                if ($seg->seats_available < $seats) {
                    return response()->json([
                        'status'  => false,
                        'message' => "Not enough seats available on segment {$seg->start_stop} → {$seg->end_stop}.",
                    ], 400);
                }
            }
        } else {
            // Simple trip: check global counter.
            if ($trip->seats_available < $seats) {
                return response()->json([
                    'status'  => false,
                    'message' => 'Not enough seats available.',
                ], 400);
            }
        }

        // ── Resolve price from driver-set segment prices ──────────────
        $unitPrice  = $this->resolvePrice($trip, $allSegs, $pickup, $dropoff);
        $tripPrice  = round($seats * $unitPrice, 2);

        // ── No-show debt: roll outstanding debt into this booking ─────
        // If the passenger has a negative balance (unpaid no-show penalty),
        // the full overdue amount is added to this trip's price and recorded
        // in debt_carried so it can be forgiven on acceptance.
        $debtCarried  = 0.00;
        $userBalance  = (float) $user->balance; // decimal:2 cast → string, force float
        if ($userBalance < 0) {
            $debtCarried = round(abs($userBalance), 2);
            $tripPrice   = round($tripPrice + $debtCarried, 2);
        }

        $booking = Booking::create([
            'trip_id'         => $trip->id,
            'passenger_id'    => $user->id,
            'pickup_stop'     => $pickup,
            'dropoff_stop'    => $dropoff,
            'seats'           => $seats,
            'total_price'     => $tripPrice,
            'debt_carried'    => $debtCarried,
            'status'          => 'pending',
            'pickup_lat'      => $request->input('pickup_lat'),
            'pickup_lng'      => $request->input('pickup_lng'),
            'pickup_address'  => $request->input('pickup_address'),
            'dropoff_lat'     => $request->input('dropoff_lat'),
            'dropoff_lng'     => $request->input('dropoff_lng'),
            'dropoff_address' => $request->input('dropoff_address'),
        ]);

        $booking->load(['trip:id,origin,destination,departure_at,driver_id', 'trip.driver:id,name,phone']);

        $route = "{$trip->origin} → {$trip->destination}";
        FcmService::bookingCreated($trip->driver, $user->name, $route);

        return response()->json([
            'status'  => true,
            'message' => 'Booking request sent. Waiting for driver to accept.',
            'booking' => $booking,
        ]);
    }

    public function myBookings(Request $request)
    {
        $user = $request->user();

        $bookings = Booking::with([
            'trip:id,origin,destination,departure_at,price_per_seat,driver_id,status,car_model,car_plate',
            'trip.driver:id,name,phone,image',
        ])
            ->where('passenger_id', $user->id)
            ->orderByDesc('id')
            ->get();

        return response()->json([
            'status'   => true,
            'bookings' => $bookings,
        ]);
    }

    public function pendingForDriver(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'driver') {
            return response()->json(['status' => false, 'message' => 'Forbidden'], 403);
        }

        $bookings = Booking::with([
            'passenger:id,name,phone,image',
            'trip:id,origin,destination,departure_at,driver_id',
        ])
            ->whereHas('trip', fn($q) => $q->where('driver_id', $user->id))
            ->orderByDesc('id')
            ->get();

        return response()->json([
            'status'   => true,
            'bookings' => $bookings,
        ]);
    }

    public function accept(Request $request, Booking $booking)
    {
        $user = $request->user();
        if ($booking->trip->driver_id !== $user->id) {
            return response()->json(['status' => false, 'message' => 'Forbidden'], 403);
        }
        if ($booking->status !== 'pending') {
            return response()->json([
                'status'  => false,
                'message' => 'Only pending bookings can be accepted.',
            ], 400);
        }

        try {
            DB::transaction(function () use ($booking) {
                $trip  = $booking->trip()->lockForUpdate()->first();
                $seats = (int) $booking->seats;

                // Determine which segments this booking covers.
                $allSegs = TripSegment::where('trip_id', $trip->id)
                    ->orderBy('order_index')
                    ->lockForUpdate()
                    ->get();

                // Path A: booking came via SegmentController (has pivot rows).
                // Seats were NOT pre-reserved — reserve them now.
                $hasPivotRows = $booking->segments()->exists();

                if ($hasPivotRows) {
                    $bookingSegIds = $booking->segments()->pluck('trip_segments.id')->toArray();
                    $coveredSegs   = $allSegs->filter(fn($s) => in_array($s->id, $bookingSegIds));

                    foreach ($coveredSegs as $seg) {
                        if ($seg->seats_available < $seats) {
                            throw new \RuntimeException(
                                "Not enough seats on {$seg->start_stop} → {$seg->end_stop} (seats may be full)"
                            );
                        }
                    }
                    foreach ($coveredSegs as $seg) {
                        $seg->decrement('seats_available', $seats);
                    }

                    $minAvail = TripSegment::where('trip_id', $trip->id)->min('seats_available');
                    $trip->update(['seats_available' => $minAvail ?? $trip->seats_available]);
                } elseif ($allSegs->isNotEmpty()) {
                    // Path B-Segments: reserve on the covered legs now.
                    $covered = $this->getSegmentsForRoute(
                        $allSegs,
                        $booking->pickup_stop  ?? $trip->origin,
                        $booking->dropoff_stop ?? $trip->destination
                    );

                    foreach ($covered as $seg) {
                        if ($seg->seats_available < $seats) {
                            throw new \RuntimeException(
                                "Not enough seats on {$seg->start_stop} → {$seg->end_stop} (seats may be full)"
                            );
                        }
                    }
                    foreach ($covered as $seg) {
                        $seg->decrement('seats_available', $seats);
                    }

                    $minAvail = TripSegment::where('trip_id', $trip->id)->min('seats_available');
                    $trip->update(['seats_available' => $minAvail]);
                } else {
                    // Path C: simple trip, no segments — use global counter.
                    if ($trip->seats_available < $seats) {
                        throw new \RuntimeException('Not enough seats remaining (seats may be full)');
                    }
                    $trip->decrement('seats_available', $seats);
                }

                $booking->update(['status' => 'accepted']);

                // ── Debt clearance ───────────────────────────────────────
                // The passenger included their outstanding no-show debt in the
                // total_price they'll pay for this trip.  Clear it from their
                // balance now so they don't get double-charged if they cancel.
                if ((float) $booking->debt_carried > 0) {
                    $booking->passenger()->first()->increment('balance', $booking->debt_carried);
                }
            });
        } catch (\RuntimeException $e) {
            return response()->json([
                'status'  => false,
                'message' => 'Could not accept (' . $e->getMessage() . ')',
            ], 400);
        }

        $route = "{$booking->trip->origin} → {$booking->trip->destination}";
        FcmService::bookingAccepted($booking->passenger, $user->name, $route);

        return response()->json([
            'status'  => true,
            'message' => 'Booking accepted.',
            'booking' => $booking->fresh(['passenger:id,name,phone', 'trip']),
        ]);
    }

    public function reject(Request $request, Booking $booking)
    {
        $user = $request->user();
        if ($booking->trip->driver_id !== $user->id) {
            return response()->json(['status' => false, 'message' => 'Forbidden'], 403);
        }
        if ($booking->status !== 'pending') {
            return response()->json([
                'status'  => false,
                'message' => 'Only pending bookings can be rejected.',
            ], 400);
        }

        DB::transaction(function () use ($booking) {
            // No seat release needed — seats are only reserved at acceptance,
            // never at booking creation, so a pending booking holds no seats.
            $booking->update(['status' => 'rejected']);
        });

        $route = "{$booking->trip->origin} → {$booking->trip->destination}";
        FcmService::bookingRejected($booking->passenger, $route);

        return response()->json([
            'status'  => true,
            'message' => 'Booking rejected.',
        ]);
    }

    public function cancel(Request $request, Booking $booking)
    {
        $user = $request->user();
        if ($booking->passenger_id !== $user->id) {
            return response()->json(['status' => false, 'message' => 'Forbidden'], 403);
        }
        if (!in_array($booking->status, ['pending', 'accepted'])) {
            return response()->json([
                'status'  => false,
                'message' => 'This booking cannot be cancelled.',
            ], 400);
        }
        if ($booking->is_checked_in) {
            return response()->json([
                'status'  => false,
                'message' => 'You cannot cancel a booking after you have already checked in.',
            ], 400);
        }

        DB::transaction(function () use ($booking) {
            $trip  = $booking->trip()->lockForUpdate()->first();
            $seats = (int) $booking->seats;

            // Only release seats if the booking was accepted — seats are reserved
            // at acceptance time, not at booking creation (pending bookings hold
            // no seats, so cancelling one doesn't need a release).
            if ($booking->status === 'accepted') {
                $allSegs = TripSegment::where('trip_id', $trip->id)
                    ->orderBy('order_index')
                    ->lockForUpdate()
                    ->get();

                if ($allSegs->isNotEmpty()) {
                    // Use explicit pivot rows (SegmentController path) or derive
                    // coverage from pickup/dropoff stops (BookingController path).
                    $segmentsToRelease = $booking->segments()->exists()
                        ? $booking->segments()->get()
                        : $this->getSegmentsForRoute(
                            $allSegs,
                            $booking->pickup_stop  ?? $trip->origin,
                            $booking->dropoff_stop ?? $trip->destination
                        );

                    foreach ($segmentsToRelease as $seg) {
                        $seg->releaseSeats($seats);
                    }

                    $minAvail = TripSegment::where('trip_id', $trip->id)->min('seats_available');
                    $trip->update(['seats_available' => $minAvail]);
                } else {
                    // Simple trip with no segments — restore global counter.
                    $trip->increment('seats_available', $seats);
                }

                // Debt was cleared from balance at acceptance; put it back
                // since the passenger is no longer paying via this booking.
                if ((float) $booking->debt_carried > 0) {
                    $booking->passenger()->first()->decrement('balance', $booking->debt_carried);
                }
            }

            $booking->update(['status' => 'cancelled']);
        });

        $route = "{$booking->trip->origin} → {$booking->trip->destination}";
        FcmService::bookingCancelledByPassenger($booking->trip->driver, $user->name, $route);

        return response()->json([
            'status'  => true,
            'message' => 'Booking cancelled.',
        ]);
    }

    public function checkIn(Request $request, Booking $booking)
    {
        $user = $request->user();

        if ($booking->passenger_id !== $user->id) {
            return response()->json(['status' => false, 'message' => 'Forbidden'], 403);
        }
        if ($booking->status !== 'accepted') {
            return response()->json([
                'status'  => false,
                'message' => 'Only accepted bookings can be checked in.',
            ], 400);
        }
        if ($booking->is_checked_in) {
            return response()->json([
                'status'  => false,
                'message' => 'You already checked in.',
            ], 400);
        }

        $departure    = Carbon::parse($booking->trip->departure_at);
        $now          = Carbon::now();
        $checkInOpen  = $departure->copy()->subMinutes(60);
        $checkInClose = $departure->copy()->addMinutes(30);

        if ($now->lt($checkInOpen)) {
            return response()->json([
                'status'   => false,
                'message'  => 'Check-in opens 60 minutes before departure.',
                'opens_at' => $checkInOpen->format('Y-m-d H:i:s'),
            ], 400);
        }
        if ($now->gt($checkInClose)) {
            return response()->json([
                'status'  => false,
                'message' => 'Check-in window has closed.',
            ], 400);
        }

        $booking->update(['is_checked_in' => true]);

        $booking->refresh()->load([
            'trip:id,origin,destination,departure_at,driver_id,min_passengers',
        ]);

        return response()->json([
            'status'  => true,
            'message' => 'Checked in successfully.',
            'booking' => $booking,
        ]);
    }

    public function driverCheckIn(Request $request, Booking $booking)
    {
        $user = $request->user();

        if ($booking->trip->driver_id !== $user->id) {
            return response()->json(['status' => false, 'message' => 'Forbidden'], 403);
        }
        if ($booking->status !== 'accepted') {
            return response()->json([
                'status'  => false,
                'message' => 'Only accepted bookings can be checked in.',
            ], 400);
        }
        if ($booking->is_checked_in) {
            return response()->json([
                'status'  => false,
                'message' => 'Passenger is already checked in.',
            ], 400);
        }

        $booking->update(['is_checked_in' => true]);

        return response()->json([
            'status'  => true,
            'message' => 'Passenger checked in.',
            'booking' => $booking->fresh(['passenger:id,name,phone']),
        ]);
    }

    public function setPaymentMethod(Request $request, Booking $booking)
    {
        $user = $request->user();

        if ($booking->passenger_id !== $user->id) {
            return response()->json(['status' => false, 'message' => 'Forbidden'], 403);
        }

        $validator = Validator::make($request->all(), [
            'payment_method' => 'required|string|in:cash,card,wallet',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
            ], 400);
        }

        $booking->update(['payment_method' => $request->input('payment_method')]);

        return response()->json([
            'status'  => true,
            'message' => 'Payment method saved.',
            'booking' => $booking->fresh(),
        ]);
    }

    private function getSegmentsForRoute(Collection $allSegs, string $from, string $to): Collection
    {
        $startIdx = $allSegs->search(fn($s) => $s->start_stop === $from);
        $endIdx   = $allSegs->search(fn($s) => $s->end_stop   === $to);

        if ($startIdx === false || $endIdx === false || $startIdx > $endIdx) {
            // Route not found — treat as full trip.
            return $allSegs;
        }

        return $allSegs->slice($startIdx, $endIdx - $startIdx + 1)->values();
    }

    protected function resolvePrice(Trip $trip, Collection $allSegs, string $pickup, string $dropoff): float
    {
        if ($allSegs->isNotEmpty()) {
            $covered = $this->getSegmentsForRoute($allSegs, $pickup, $dropoff);
            if ($covered->isNotEmpty()) {
                return (float) $covered->sum('price');
            }
        }
        $base  = (float) $trip->price_per_seat;
        $stops = $trip->stops->pluck('name')->values();
        if ($stops->count() < 2) {
            return $base;
        }
        $iFrom = $stops->search($pickup,  true);
        $iTo   = $stops->search($dropoff, true);
        if ($iFrom === false || $iTo === false || $iTo <= $iFrom) {
            return $base;
        }
        $totalSeg = $stops->count() - 1;
        return round($base * (($iTo - $iFrom) / $totalSeg), 2);
    }
}
