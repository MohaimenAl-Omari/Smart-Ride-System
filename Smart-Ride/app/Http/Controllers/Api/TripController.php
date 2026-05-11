<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class TripController extends Controller
{
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
            'origin'         => 'required|string|max:120',
            'destination'    => 'required|string|max:120',
            'departure_at'   => 'required|date|after:now',
            'seats_total'    => 'required|integer|min:1|max:10',
            'min_passengers' => 'nullable|integer|min:1',
            'price_per_seat' => 'required|numeric|min:0',
            'car_model'      => 'nullable|string|max:120',
            'car_plate'      => 'nullable|string|max:30',
            'notes'          => 'nullable|string|max:500',
            'stops'          => 'nullable|array',
            'stops.*'        => 'string|max:120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
            ], 400);
        }

        $trip = DB::transaction(function () use ($request, $user) {
            $trip = Trip::create([
                'driver_id'       => $user->id,
                'origin'          => $request->origin,
                'destination'     => $request->destination,
                'departure_at'    => $request->departure_at,
                'seats_total'     => $request->seats_total,
                'seats_available' => $request->seats_total,
                'min_passengers'  => $request->min_passengers ?? 1,
                'price_per_seat'  => $request->price_per_seat,
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

            return $trip->load('stops');
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

        $checkedIn = $trip->bookings()
            ->where('status', 'accepted')
            ->whereNotNull('checked_in_at')
            ->count();

            // this condidtion must be checked
        // if ($checkedIn <= $trip->min_passengers) {
        //     return response()->json([
        //         'status'  => false,
        //         'message' => "Cannot start: only {$checkedIn} of {$trip->min_passengers} required passengers have checked in.",
        //     ], 400);
        // }

        $trip->update(['status' => 'in_progress']);
        return response()->json([
            'status'  => true,
            'message' => 'Trip started.',
            'checked_in_count' => $checkedIn,
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

            // Flag no-shows: accepted bookings without a check-in timestamp.
            $trip->bookings()
                ->where('status', 'accepted')
                ->whereNull('checked_in_at')
                ->update(['no_show' => true]);

            $trip->bookings()
                ->where('status', 'accepted')
                ->update(['status' => 'completed']);
        });

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
