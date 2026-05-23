<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use App\Services\FcmService;
use App\Services\TripSegmentationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class TripController extends Controller
{
    public function __construct(private TripSegmentationService $segSvc) {}

    public function search(Request $request)
    {
        $query = Trip::query()
            ->with(['driver:id,name,phone,city,image', 'stops'])
            ->where('status', 'scheduled')
            ->where('seats_available', '>', 0)
            ->where('departure_at', '>=', now());

        if ($request->filled('from')) {
            $query->where('origin', 'like', '%' . $request->from . '%');
        }
        if ($request->filled('to')) {
            $query->where('destination', 'like', '%' . $request->to . '%');
        }
        if ($request->filled('date')) {
            $query->whereDate('departure_at', $request->date);
        }

        $trips = $query->orderBy('departure_at')->limit(60)->get();

        return response()->json([
            'status' => true,
            'trips'  => $trips,
        ]);
    }

    public function show(Trip $trip)
    {
        $trip->load(['driver:id,name,phone,city,image', 'stops']);
        return response()->json([
            'status' => true,
            'trip'   => $trip,
        ]);
    }

    public function myDriverTrips(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'driver') {
            return response()->json([
                'status'  => false,
                'message' => 'Only drivers can access this endpoint.',
            ], 403);
        }

        $trips = Trip::with(['stops', 'bookings.passenger:id,name,phone'])
            ->where('driver_id', $user->id)
            ->orderByDesc('departure_at')
            ->get();

        return response()->json([
            'status' => true,
            'trips'  => $trips,
        ]);
    }

    public function store(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'driver') {
            return response()->json([
                'status'  => false,
                'message' => 'Only drivers can create trips.',
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'origin'          => 'required|string|max:120',
            'destination'     => 'required|string|max:120',
            'departure_at'    => 'required|date|after:now',
            'seats_total'     => 'required|integer|min:1|max:10',
            'min_passengers'  => 'nullable|integer|min:1',
            // price_per_seat is optional — the real prices live in segment_prices.
            // When segment_prices is provided, price_per_seat is auto-derived as
            // their sum (full trip price).  A fallback value of 0 is accepted so
            // the column is never null.
            'price_per_seat'   => 'nullable|numeric|min:0',
            'car_model'        => 'nullable|string|max:120',
            'car_plate'        => 'nullable|string|max:30',
            'notes'            => 'nullable|string|max:500',
            'stops'            => 'nullable|array',
            'stops.*'          => 'string|max:120',
            // Per-segment prices: ordered floats, one per consecutive stop pair.
            // e.g. Irbid→Amman=10, Amman→Aqaba=15 → [10.0, 15.0]
            // Every element must be ≥ 0.01 so no leg is free by accident.
            'segment_prices'   => 'required|array|min:1',
            'segment_prices.*' => 'numeric|min:0.01',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
            ], 400);
        }

        $trip = DB::transaction(function () use ($request, $user) {
            $segmentPrices = array_map(
                'floatval',
                $request->input('segment_prices', [])
            );

            // Derive price_per_seat = sum of all segment prices (= full trip cost).
            // This value is used for display on listing cards. Per-leg prices are
            // authoritative and stored in trip_segments.price.
            $totalPrice = !empty($segmentPrices)
                ? array_sum($segmentPrices)
                : (float) ($request->price_per_seat ?? 0);

            $trip = Trip::create([
                'driver_id'       => $user->id,
                'origin'          => $request->origin,
                'destination'     => $request->destination,
                'departure_at'    => $request->departure_at,
                'seats_total'     => $request->seats_total,
                'seats_available' => $request->seats_total,
                'min_passengers'  => $request->min_passengers ?? 1,
                'price_per_seat'  => $totalPrice,
                'car_model'       => $request->car_model,
                'car_plate'       => $request->car_plate,
                'notes'           => $request->notes,
                'status'          => 'scheduled',
            ]);

            $stops = collect([$request->origin])
                ->merge($request->input('stops', []))
                ->push($request->destination)
                ->values();

            foreach ($stops as $i => $stop) {
                $trip->stops()->create([
                    'name'        => $stop,
                    'order_index' => $i,
                ]);
            }

            // Auto-generate per-leg segments with driver-set prices.
            // Trip is immediately bookable — no separate generate call needed.
            $this->segSvc->generateSegments($trip->fresh('stops'), $segmentPrices);

            return $trip->load(['stops', 'segments']);
        });

        return response()->json([
            'status'  => true,
            'message' => 'Trip created successfully.',
            'trip'    => $trip,
        ]);
    }

    public function cancel(Request $request, Trip $trip)
    {
        $user = $request->user();
        if ($trip->driver_id !== $user->id) {
            return response()->json([
                'status'  => false,
                'message' => 'You do not own this trip.',
            ], 403);
        }
        if ($trip->status !== 'scheduled') {
            return response()->json([
                'status'  => false,
                'message' => 'Only scheduled trips can be cancelled.',
            ], 400);
        }
        DB::transaction(function () use ($trip) {
            $trip->update(['status' => 'cancelled']);
            $trip->bookings()
                ->whereIn('status', ['pending', 'accepted'])
                ->update(['status' => 'cancelled']);
        });

        // Notify all affected passengers about the cancellation.
        $route = "{$trip->origin} → {$trip->destination}";
        $trip->bookings()
            ->where('status', 'cancelled')
            ->with('passenger')
            ->get()
            ->each(fn ($b) => FcmService::tripCancelledByDriver($b->passenger, $route));

        return response()->json([
            'status'  => true,
            'message' => 'Trip cancelled.',
        ]);
    }


    public function start(Request $request, Trip $trip)
    {
        $user = $request->user();
        if ($trip->driver_id !== $user->id) {
            return response()->json(['status' => false, 'message' => 'Forbidden'], 403);
        }
        if ($trip->status !== 'scheduled') {
            return response()->json([
                'status'  => false,
                'message' => 'Only scheduled trips can be started.',
            ], 400);
        }

        $route      = "{$trip->origin} → {$trip->destination}";
        $noShowCount = 0;

        DB::transaction(function () use ($trip, $route, &$noShowCount) {
            $trip->update(['status' => 'in_progress']);

            // ── No-show handling ──────────────────────────────────────────
            // Find every accepted booking whose passenger never checked in.
            $noShows = $trip->bookings()
                ->where('status', 'accepted')
                ->where('is_checked_in', false)
                ->with(['passenger', 'segments'])
                ->get();

            foreach ($noShows as $booking) {
                // Mark the booking as no-show.
                $booking->update(['no_show' => true]);

                // Deduct the booking price from the passenger's balance.
                // decimal:2 cast returns a string, so cast explicitly to float.
                $passenger   = $booking->passenger;
                $bookingCost = (float) $booking->total_price;
                $passenger->decrement('balance', $bookingCost);

                // Release reserved segment seats (use already-loaded relation,
                // not ->exists() which fires an extra query).
                if ($booking->segments->isNotEmpty()) {
                    foreach ($booking->segments as $seg) {
                        $seg->increment('seats_available', (int) $booking->seats);
                    }
                    // Re-sync the trip's displayed seats_available counter.
                    $minAvail = $trip->segments()->min('seats_available');
                    $trip->update(['seats_available' => $minAvail ?? $trip->seats_available]);
                } else {
                    // No segment tracking — restore the global counter.
                    $trip->increment('seats_available', (int) $booking->seats);
                }

                // Notify the passenger about the penalty.
                FcmService::noShowPenalty($passenger, $route, $bookingCost);

                $noShowCount++;
            }

            // Notify checked-in passengers that the trip has started.
            $trip->bookings()
                ->where('status', 'accepted')
                ->where('is_checked_in', true)
                ->with('passenger')
                ->get()
                ->each(fn ($b) => FcmService::tripStarted($b->passenger, $route));
        });

        $checkedIn = $trip->bookings()
            ->where('status', 'accepted')
            ->where('is_checked_in', true)
            ->count();

        return response()->json([
            'status'           => true,
            'message'          => 'Trip started.',
            'checked_in_count' => $checkedIn,
            'no_show_count'    => $noShowCount,
        ]);
    }


    public function complete(Request $request, Trip $trip)
    {
        $user = $request->user();
        if ($trip->driver_id !== $user->id) {
            return response()->json(['status' => false, 'message' => 'Forbidden'], 403);
        }

        DB::transaction(function () use ($trip) {
            $trip->update(['status' => 'completed']);

            // Mark checked-in passengers as completed (no-shows were already handled
            // in start() and must NOT be overwritten to 'completed').
            $trip->bookings()
                ->where('status', 'accepted')
                ->where('is_checked_in', true)
                ->update(['status' => 'completed']);
        });

        // Notify completed passengers to rate their driver.
        $driverName = $user->name;
        $trip->bookings()
            ->where('status', 'completed')
            ->with('passenger')
            ->get()
            ->each(fn ($b) => FcmService::tripCompleted($b->passenger, $driverName));

        return response()->json(['status' => true, 'message' => 'Trip completed.']);
    }


    public function driverHistory(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'driver') {
            return response()->json([
                'status'  => false,
                'message' => 'Only drivers can access this endpoint.',
            ], 403);
        }

        $trips = Trip::with(['stops'])
            ->withSum([
                'bookings as passengers_count' => function ($q) {
                    $q->whereIn('status', ['accepted', 'completed']);
                },
            ], 'seats')
            ->withSum([
                'bookings as total_earnings' => function ($q) {
                    $q->whereIn('status', ['accepted', 'completed']);
                },
            ], 'total_price')
            ->where('driver_id', $user->id)
            ->whereIn('status', ['completed', 'cancelled'])
            ->orderByDesc('departure_at')
            ->limit(60)
            ->get();

        return response()->json([
            'status' => true,
            'trips'  => $trips,
        ]);
    }
}
