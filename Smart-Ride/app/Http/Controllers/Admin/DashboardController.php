<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Support\Facades\Storage;

class DashboardController extends Controller
{
    public function index()
    {
        $stats = [
            'passengers'       => User::where('role', 'passenger')->count(),
            'drivers'          => User::where('role', 'driver')->where('is_active', true)->count(),
            'pending_drivers'  => User::where('role', 'driver')->where('is_active', false)->count(),
            'trips'            => Trip::count(),
            'active_trips'     => Trip::whereIn('status', ['scheduled', 'in_progress'])->count(),
            'bookings'         => Booking::count(),
            'pending_bookings' => Booking::where('status', 'pending')->count(),
            'completed_trips'  => Trip::where('status', 'completed')->count(),
        ];

        $pendingDrivers = User::where('role', 'driver')
            ->where('is_active', false)
            ->with('certificate')
            ->latest()
            ->take(5)
            ->get();

        $recentTrips = Trip::with('driver:id,name')
            ->latest()
            ->take(8)
            ->get();

        $recentBookings = Booking::with([
            'passenger:id,name',
            'trip:id,origin,destination',
        ])
            ->latest()
            ->take(8)
            ->get();

        return view('admin.dashboard', compact(
            'stats',
            'pendingDrivers',
            'recentTrips',
            'recentBookings'
        ));
    }

    public function approve(User $user)
    {
        abort_unless($user->role === 'driver', 404);
        $user->update(['is_active' => true, 'is_verified' => true]);
        return redirect()
            ->back()
            ->with('status', "{$user->name} has been approved.");
    }

    public function reject(User $user)
    {
        abort_unless($user->role === 'driver', 404);

        if ($cert = $user->certificate) {
            foreach (['license_path', 'non_conviction_path', 'medical_path'] as $field) {
                if ($cert->{$field}) {
                    Storage::delete($cert->{$field});
                }
            }
        }

        $name = $user->name;
        $user->delete();

        return redirect()
            ->back()
            ->with('status', "{$name}'s application was rejected and removed.");
    }

    public function certificate(User $user, string $type)
    {
        abort_unless($user->role === 'driver', 404);

        $map = [
            'license'        => 'license_path',
            'non_conviction' => 'non_conviction_path',
            'medical'        => 'medical_path',
        ];

        if (!isset($map[$type])) {
            abort(404);
        }

        $cert = $user->certificate;
        if (!$cert || !$cert->{$map[$type]}) {
            abort(404);
        }

        $path = $cert->{$map[$type]};
        if (!Storage::exists($path)) {
            abort(404);
        }

        return response()->file(Storage::path($path), [
            'Content-Disposition' => 'inline; filename="' . basename($path) . '"',
        ]);
    }
}
