@extends('admin.layout')

@section('title', 'Users')

@section('content')
    <div class="mb-8">
        <div class="text-xs uppercase tracking-widest text-indigo-300/80">Identity</div>
        <h1 class="mt-1 text-3xl font-bold tracking-tight">Users</h1>
        <p class="mt-1 text-sm text-slate-400">All passengers and drivers across Smart Ride.</p>
    </div>

    <form method="GET" action="{{ route('admin.users') }}"
          class="mb-6 flex flex-wrap gap-3 rounded-2xl border border-white/10 bg-white/[0.04] p-3">
        <div class="relative flex-1 min-w-[200px]">
            <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            <input name="q" value="{{ $search }}" placeholder="Search by name, email or phone..."
                   class="w-full rounded-lg border border-white/10 bg-slate-950/40 pl-9 pr-3 py-2 text-sm outline-none focus:border-indigo-400">
        </div>

        <div class="flex gap-1 rounded-lg border border-white/10 bg-slate-950/40 p-1">
            @foreach (['all' => 'All', 'passenger' => 'Passengers', 'driver' => 'Drivers'] as $value => $label)
                <a href="{{ route('admin.users', ['role' => $value, 'q' => $search]) }}"
                   class="rounded-md px-3 py-1.5 text-xs font-medium transition
                          {{ $role === $value ? 'bg-gradient-to-r from-indigo-500 to-cyan-500 text-white' : 'text-slate-400 hover:text-white' }}">
                    {{ $label }}
                </a>
            @endforeach
        </div>

        <button class="rounded-lg border border-white/10 bg-white/5 px-3 py-2 text-xs text-slate-200 hover:bg-white/10">
            Apply
        </button>
    </form>

    <div class="rounded-2xl border border-white/10 bg-white/[0.04] overflow-hidden">
        <table class="min-w-full divide-y divide-white/5 text-sm">
            <thead class="bg-white/[0.03] text-[11px] uppercase tracking-wide text-slate-400">
                <tr>
                    <th class="px-4 py-3 text-left font-medium">User</th>
                    <th class="px-4 py-3 text-left font-medium">Role</th>
                    <th class="px-4 py-3 text-left font-medium">Trips</th>
                    <th class="px-4 py-3 text-left font-medium">Bookings</th>
                    <th class="px-4 py-3 text-left font-medium">Status</th>
                    <th class="px-4 py-3 text-left font-medium">Joined</th>
                    <th class="px-4 py-3 text-right font-medium">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-white/5">
                @forelse($users as $user)
                    <tr class="hover:bg-white/[0.02]">
                        <td class="px-4 py-3">
                            <div class="flex items-center gap-3">
                                <div class="grid h-9 w-9 place-items-center rounded-lg bg-gradient-to-br from-indigo-500 to-cyan-500 text-sm font-bold">
                                    {{ strtoupper(substr($user->name, 0, 1)) }}
                                </div>
                                <div>
                                    <div class="text-white font-medium">{{ $user->name }}</div>
                                    <div class="text-[11px] text-slate-500">{{ $user->email }} · {{ $user->phone }}</div>
                                </div>
                            </div>
                        </td>
                        <td class="px-4 py-3">
                            @if($user->role === 'driver')
                                <span class="inline-flex items-center gap-1 rounded-full bg-cyan-500/15 px-2 py-0.5 text-[11px] font-medium text-cyan-300">Driver</span>
                            @else
                                <span class="inline-flex items-center gap-1 rounded-full bg-indigo-500/15 px-2 py-0.5 text-[11px] font-medium text-indigo-300">Passenger</span>
                            @endif
                        </td>
                        <td class="px-4 py-3 text-slate-300">{{ $user->trips_as_driver_count }}</td>
                        <td class="px-4 py-3 text-slate-300">{{ $user->bookings_count }}</td>
                        <td class="px-4 py-3">
                            @if($user->is_active)
                                <span class="inline-flex items-center gap-1.5 rounded-full bg-emerald-500/15 px-2.5 py-0.5 text-[11px] font-medium text-emerald-300">
                                    <span class="h-1.5 w-1.5 rounded-full bg-current"></span>Active
                                </span>
                            @else
                                <span class="inline-flex items-center gap-1.5 rounded-full bg-amber-500/15 px-2.5 py-0.5 text-[11px] font-medium text-amber-300">
                                    <span class="h-1.5 w-1.5 rounded-full bg-current"></span>Inactive
                                </span>
                            @endif
                        </td>
                        <td class="px-4 py-3 text-xs text-slate-500">{{ $user->created_at->format('M d, Y') }}</td>
                        <td class="px-4 py-3 text-right">
                            <div class="flex justify-end gap-2">
                                <form method="POST" action="{{ route('admin.users.toggle', $user) }}">
                                    @csrf
                                    <button class="rounded-md border border-white/10 bg-white/5 px-2.5 py-1 text-[11px] text-slate-200 hover:bg-white/10">
                                        {{ $user->is_active ? 'Deactivate' : 'Activate' }}
                                    </button>
                                </form>
                                <form method="POST" action="{{ route('admin.users.destroy', $user) }}"
                                      onsubmit="return confirm('Permanently delete this user?');">
                                    @csrf
                                    @method('DELETE')
                                    <button class="rounded-md border border-rose-500/30 bg-rose-500/10 px-2.5 py-1 text-[11px] text-rose-300 hover:bg-rose-500/15">
                                        Delete
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="7" class="px-4 py-12 text-center text-sm text-slate-400">No users match your filters.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">{{ $users->links() }}</div>
@endsection
