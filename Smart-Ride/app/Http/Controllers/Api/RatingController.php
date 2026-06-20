<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\FcmService;
use App\Models\Booking;
use App\Models\TripRating;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class RatingController extends Controller
{
    public function store(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'passenger') {
            return response()->json([
                'status'  => false,
                'message' => 'Only passengers can rate drivers.',
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'booking_id' => 'required|exists:bookings,id',
            'stars'      => 'required|integer|min:1|max:5',
            'review'     => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
                'errors'  => $validator->errors(),
            ], 400);
        }

        $booking = Booking::with('trip')->findOrFail($request->booking_id);

        // The booking must belong to the rater
        if ($booking->passenger_id !== $user->id) {
            return response()->json([
                'status'  => false,
                'message' => 'You can only rate your own bookings.',
            ], 403);
        }

        // Trip must be completed
        if ($booking->status !== 'completed' && $booking->trip->status !== 'completed') {
            return response()->json([
                'status'  => false,
                'message' => 'You can only rate after the trip completes.',
            ], 400);
        }

        // Prevent duplicates – DB constraint also covers this but
        // we surface a friendly error.
        $exists = TripRating::where('booking_id', $booking->id)
            ->where('passenger_id', $user->id)
            ->exists();

        if ($exists) {
            return response()->json([
                'status'  => false,
                'message' => 'You already rated this trip.',
            ], 400);
        }

        $rating = TripRating::create([
            'booking_id'   => $booking->id,
            'trip_id'      => $booking->trip_id,
            'passenger_id' => $user->id,
            'driver_id'    => $booking->trip->driver_id,
            'stars'        => $request->stars,
            'review'       => $request->review,
        ]);

        // Return the updated driver aggregates for instant UI refresh.
        $driver = User::find($booking->trip->driver_id);

        // Notify the driver about the new rating.
        if ($driver) {
            FcmService::driverRated($driver, (int) $request->stars, $user->name);
        }

        return response()->json([
            'status'  => true,
            'message' => 'Thanks for rating!',
            'rating'  => $rating,
            'driver'  => [
                'id'             => $driver?->id,
                'rating_average' => $driver?->rating_average,
                'ratings_count'  => $driver?->ratings_count,
            ],
        ]);
    }

    public function forDriver(User $driver)
    {
        if ($driver->role !== 'driver') {
            return response()->json([
                'status'  => false,
                'message' => 'User is not a driver.',
            ], 400);
        }

        $ratings = TripRating::with('passenger:id,name,image')
            ->where('driver_id', $driver->id)
            ->orderByDesc('id')
            ->limit(60)
            ->get();

        return response()->json([
            'status'         => true,
            'rating_average' => $driver->rating_average,
            'ratings_count'  => $driver->ratings_count,
            'ratings'        => $ratings,
        ]);
    }
}
