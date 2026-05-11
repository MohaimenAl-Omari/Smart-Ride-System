<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $role   = $request->input('role', 'all');
        $search = trim((string) $request->input('q', ''));

        $query = User::query()
            ->where('role', '!=', 'admin')
            ->withCount(['tripsAsDriver', 'bookings']);

        if (in_array($role, ['passenger', 'driver'])) {
            $query->where('role', $role);
        }
        if ($search !== '') {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        $users = $query->latest()->paginate(15)->withQueryString();

        return view('admin.users', compact('users', 'role', 'search'));
    }

    public function pendingDrivers()
    {
        $pendingDrivers = User::where('role', 'driver')
            ->where('is_active', false)
            ->with('certificate')
            ->latest()
            ->get();

        return view('admin.pending_drivers', compact('pendingDrivers'));
    }

    public function toggleActive(User $user)
    {
        abort_if($user->role === 'admin', 403);
        $user->update(['is_active' => !$user->is_active]);
        return redirect()
            ->back()
            ->with('status', $user->is_active
                ? "{$user->name} has been activated."
                : "{$user->name} has been deactivated.");
    }

    public function destroy(User $user)
    {
        abort_if($user->role === 'admin', 403);
        $name = $user->name;
        $user->delete();
        return redirect()
            ->back()
            ->with('status', "{$name} has been removed.");
    }
}
