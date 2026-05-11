<?php

namespace App\Http\Controllers\Api;

use Carbon\Carbon;
use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Trip;
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
            'trip_id'      => 'required|exists:trips,id',
            'seats'        => 'required|integer|min:1|max:6',
            'pickup_stop'  => 'nullable|string|max:120',
            'dropoff_stop' => 'nullable|string|max:120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
            ], 400);
        }

        $trip = Trip::with('stops')->findOrFail($request->trip_id);

        if ($trip->status !== 'scheduled') {
            return response()->json([
                'status'  => false,
                'message' => 'This trip is not available for booking.',
            ], 400);
        }
        if ($trip->seats_available < $request->seats) {
            return response()->json([
                'status'  => false,
                'message' => 'Not enough seats available.',
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
        $pickup  = $request->pickup_stop ?? $trip->origin;
        $dropoff = $request->dropoff_stop ?? $trip->destination;
        $unitPrice = $this->resolveSegmentPrice($trip, $pickup, $dropoff);

        $booking = Booking::create([
            'trip_id'      => $trip->id,
            'passenger_id' => $user->id,
            'pickup_stop'  => $pickup,
            'dropoff_stop' => $dropoff,
            'seats'        => $request->seats,
            'total_price'  => round($request->seats * $unitPrice, 2),
            'status'       => 'pending',
        ]);

        $booking->load(['trip:id,origin,destination,departure_at,driver_id', 'trip.driver:id,name,phone']);

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

        DB::transaction(function () use ($booking) {
            $trip = $booking->trip()->lockForUpdate()->first();
            if ($trip->seats_available < $booking->seats) {
                throw new \RuntimeException('Not enough seats remaining.');
            }
            $trip->decrement('seats_available', $booking->seats);
            $booking->update(['status' => 'accepted']);
        });

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

        $booking->update(['status' => 'rejected']);

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

        DB::transaction(function () use ($booking) {
            if ($booking->status === 'accepted') {
                $booking->trip()->increment('seats_available', $booking->seats);
            }
            $booking->update(['status' => 'cancelled']);
        });

        return response()->json([
            'status'  => true,
            'message' => 'Booking cancelled.',
        ]);
    }

    public function checkIn(Request $request, Booking $booking)
    {
        $user = $request->user();

        // Ensure passenger owns this booking
        if ($booking->passenger_id !== $user->id) {
            return response()->json([
                'status' => false,
                'message' => 'Forbidden'
            ], 403);
        }

        // Only accepted bookings can check in
        if ($booking->status !== 'accepted') {
            return response()->json([
                'status'  => false,
                'message' => 'Only accepted bookings can be checked in.',
            ], 400);
        }

        // Prevent double check-in
        if ($booking->checked_in_at !== null) {
            return response()->json([
                'status'  => false,
                'message' => 'You already checked in.',
            ], 400);
        }

        // Get trip
        $trip = $booking->trip;

        // Ensure departure_at is Carbon instance
        $departure = Carbon::parse($trip->departure_at);

        // Current time
        $now = Carbon::now();

        // Check-in window
        $checkInOpen  = $departure->copy()->subMinutes(60);
        $checkInClose = $departure->copy()->addMinutes(30);

        // Check if check-in is too early
        if ($now->lt($checkInOpen)) {
            return response()->json([
                'status'  => false,
                'message' => 'Check-in opens 60 minutes before departure.',
                'opens_at' => $checkInOpen->format('Y-m-d H:i:s'),
            ], 400);
        }

        // Check if check-in is too late
        if ($now->gt($checkInClose)) {
            return response()->json([
                'status'  => false,
                'message' => 'Check-in window has closed.',
            ], 400);
        }

        // Save check-in time
        $booking->checked_in_at = $now;
        $booking->save();

        // Refresh booking with trip data
        $booking->refresh()->load([
            'trip:id,origin,destination,departure_at,driver_id,min_passengers',
        ]);

        return response()->json([
            'status'  => true,
            'message' => 'Checked in successfully.',
            'booking' => $booking,
        ]);
    }

    protected function resolveSegmentPrice(Trip $trip, ?string $pickup, ?string $dropoff): float
    {
        $base = (float) $trip->price_per_seat;

        $stops = $trip->stops->pluck('name')->values();
        if ($stops->count() < 2) {
            $stops = collect([$trip->origin, $trip->destination]);
        }

        if ($pickup === null || $dropoff === null) {
            return $base;
        }

        $iFrom = $stops->search($pickup, true);
        $iTo   = $stops->search($dropoff, true);

        if ($iFrom === false || $iTo === false || $iTo <= $iFrom) {
            return $base;
        }

        $totalSegments = $stops->count() - 1;
        if ($totalSegments <= 0) {
            return $base;
        }

        $segments = $iTo - $iFrom;
        return round($base * ($segments / $totalSegments), 2);
    }
}
