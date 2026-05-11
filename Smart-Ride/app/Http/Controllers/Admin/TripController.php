<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use Illuminate\Http\Request;

class TripController extends Controller
{
    public function index(Request $request)
    {
        $status = $request->input('status', 'all');
        $search = trim((string) $request->input('q', ''));

        $query = Trip::query()->with('driver:id,name,phone')->withCount('bookings');

        if (in_array($status, ['scheduled', 'in_progress', 'completed', 'cancelled'])) {
            $query->where('status', $status);
        }
        if ($search !== '') {
            $query->where(function ($q) use ($search) {
                $q->where('origin', 'like', "%{$search}%")
                    ->orWhere('destination', 'like', "%{$search}%");
            });
        }

        $trips = $query->orderByDesc('departure_at')->paginate(15)->withQueryString();

        return view('admin.trips', compact('trips', 'status', 'search'));
    }

    public function show(Trip $trip)
    {
        $trip->load([
            'driver',
            'stops',
            'bookings.passenger',
        ]);
        return view('admin.trip_show', compact('trip'));
    }
}
