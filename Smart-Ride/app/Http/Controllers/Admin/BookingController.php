<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use Illuminate\Http\Request;

class BookingController extends Controller
{
    public function index(Request $request)
    {
        $status = $request->input('status', 'all');

        $query = Booking::with([
            'passenger:id,name,phone',
            'trip:id,origin,destination,departure_at,driver_id',
            'trip.driver:id,name',
        ]);

        if (in_array($status, ['pending', 'accepted', 'rejected', 'cancelled', 'completed'])) {
            $query->where('status', $status);
        }

        $bookings = $query->latest()->paginate(20)->withQueryString();

        return view('admin.bookings', compact('bookings', 'status'));
    }
}
