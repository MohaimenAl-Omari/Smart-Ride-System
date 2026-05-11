@extends('admin.layout')

@section('title', 'Overview')

@section('content')
    <div class="mb-8 flex flex-wrap items-end justify-between gap-3">
        <div>
            <div class="text-xs uppercase tracking-widest text-indigo-300/80">Operations overview</div>
            <h1 class="mt-1 text-3xl font-bold tracking-tight">Hello, {{ explode(' ', auth()->user()->name)[0] }}</h1>
            <p class="mt-1 text-sm text-slate-400">Snapshot of Smart Ride activity right now.</p>
        </div>
        <a href="{{ route('admin.drivers.pending') }}"
           class="rounded-xl border border-amber-400/30 bg-amber-500/10 px-3 py-2 text-xs font-medium text-amber-200 hover:bg-amber-500/15 transition">
            {{ $stats['pending_drivers'] }} drivers awaiting review
        </a>
    </div>

    <div class="grid grid-cols-2 gap-4 lg:grid-cols-4 mb-10">
        @include('admin._partials.stat_card', [
            'label' => 'Passengers',
            'value' => number_format($stats['passengers']),
            'color' => 'indigo',
            'icon'  => '<svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M4 22v-2a6 6 0 0 1 6-6h4a6 6 0 0 1 6 6v2"/></svg>',
        ])
        @include('admin._partials.stat_card', [
            'label' => 'Active drivers',
            'value' => number_format($stats['drivers']),
            'color' => 'cyan',
            'hint'  => $stats['pending_drivers'] . ' awaiting approval',
            'icon'  => '<svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M6 22v-2a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v2"/></svg>',
        ])
        @include('admin._partials.stat_card', [
            'label' => 'Active trips',
            'value' => number_format($stats['active_trips']),
            'color' => 'emerald',
            'hint'  => $stats['trips'] . ' total trips',
            'icon'  => '<svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="6" cy="19" r="3"/><path d="M9 19h8.5a3.5 3.5 0 0 0 0-7h-11a3.5 3.5 0 0 1 0-7H15"/><circle cx="18" cy="5" r="3"/></svg>',
        ])
        @include('admin._partials.stat_card', [
            'label' => 'Bookings',
            'value' => number_format($stats['bookings']),
            'color' => 'amber',
            'hint'  => $stats['pending_bookings'] . ' pending',
            'icon'  => '<svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 7a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v3a2 2 0 0 0 0 4v3a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-3a2 2 0 0 0 0-4z"/></svg>',
        ])
    </div>

    <div class="grid gap-6 lg:grid-cols-3">
        <div class="lg:col-span-2 rounded-2xl border border-white/10 bg-white/[0.04] p-6">
            <div class="flex items-center justify-between mb-4">
                <h2 class="text-base font-semibold">Recent trips</h2>
                <a href="{{ route('admin.trips') }}" class="text-xs text-cyan-300 hover:text-cyan-200">View all →</a>
            </div>

            @if($recentTrips->isEmpty())
                <div class="rounded-xl border border-white/10 bg-slate-950/40 px-4 py-10 text-center text-sm text-slate-400">
                    No trips have been created yet.
                </div>
            @else
                <div class="overflow-hidden rounded-xl border border-white/10">
                    <table class="min-w-full divide-y divide-white/5 text-sm">
                        <thead class="bg-white/[0.03] text-[11px] uppercase tracking-wide text-slate-400">
                            <tr>
                                <th class="px-4 py-3 text-left font-medium">Route</th>
                                <th class="px-4 py-3 text-left font-medium">Driver</th>
                                <th class="px-4 py-3 text-left font-medium">When</th>
                                <th class="px-4 py-3 text-left font-medium">Status</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-white/5">
                            @foreach($recentTrips as $trip)
                                <tr class="hover:bg-white/[0.02]">
                                    <td class="px-4 py-3">
                                        <div class="font-medium text-white">{{ $trip->origin }} → {{ $trip->destination }}</div>
                                        <div class="text-[11px] text-slate-500">{{ $trip->seats_available }}/{{ $trip->seats_total }} seats</div>
                                    </td>
                                    <td class="px-4 py-3 text-slate-300">{{ $trip->driver?->name ?? '—' }}</td>
                                    <td class="px-4 py-3 text-slate-400 text-xs">{{ $trip->departure_at?->format('M d, H:i') }}</td>
                                    <td class="px-4 py-3">@include('admin._partials.status_badge', ['status' => $trip->status])</td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </div>

        <div class="rounded-2xl border border-white/10 bg-white/[0.04] p-6">
            <div class="flex items-center justify-between mb-4">
                <h2 class="text-base font-semibold">Pending drivers</h2>
                <a href="{{ route('admin.drivers.pending') }}" class="text-xs text-cyan-300 hover:text-cyan-200">All →</a>
            </div>

            @if($pendingDrivers->isEmpty())
                <div class="rounded-xl border border-white/10 bg-slate-950/40 px-4 py-8 text-center text-sm text-slate-400">
                    No drivers waiting for approval.
                </div>
            @else
                <div class="space-y-3">
                    @foreach($pendingDrivers as $driver)
                        <div class="flex items-center justify-between rounded-xl border border-white/10 bg-slate-950/30 p-3">
                            <div class="flex items-center gap-3">
                                <div class="grid h-9 w-9 place-items-center rounded-lg bg-gradient-to-br from-indigo-500 to-cyan-500 text-sm font-bold">
                                    {{ strtoupper(substr($driver->name, 0, 1)) }}
                                </div>
                                <div>
                                    <div class="text-sm font-medium text-white">{{ $driver->name }}</div>
                                    <div class="text-[11px] text-slate-400">{{ $driver->email }}</div>
                                </div>
                            </div>
                            <a href="{{ route('admin.drivers.pending') }}"
                               class="rounded-lg border border-white/10 bg-white/5 px-2.5 py-1 text-[11px] text-slate-200 hover:bg-white/10">Review</a>
                        </div>
                    @endforeach
                </div>
            @endif
        </div>
    </div>

    <div class="mt-6 rounded-2xl border border-white/10 bg-white/[0.04] p-6">
        <div class="flex items-center justify-between mb-4">
            <h2 class="text-base font-semibold">Recent bookings</h2>
            <a href="{{ route('admin.bookings') }}" class="text-xs text-cyan-300 hover:text-cyan-200">View all →</a>
        </div>

        @if($recentBookings->isEmpty())
            <div class="rounded-xl border border-white/10 bg-slate-950/40 px-4 py-10 text-center text-sm text-slate-400">
                No bookings yet.
            </div>
        @else
            <div class="overflow-hidden rounded-xl border border-white/10">
                <table class="min-w-full divide-y divide-white/5 text-sm">
                    <thead class="bg-white/[0.03] text-[11px] uppercase tracking-wide text-slate-400">
                        <tr>
                            <th class="px-4 py-3 text-left font-medium">Passenger</th>
                            <th class="px-4 py-3 text-left font-medium">Trip</th>
                            <th class="px-4 py-3 text-left font-medium">Seats</th>
                            <th class="px-4 py-3 text-left font-medium">Total</th>
                            <th class="px-4 py-3 text-left font-medium">Status</th>
                            <th class="px-4 py-3 text-left font-medium">Date</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-white/5">
                        @foreach($recentBookings as $booking)
                            <tr class="hover:bg-white/[0.02]">
                                <td class="px-4 py-3 text-white">{{ $booking->passenger?->name ?? '—' }}</td>
                                <td class="px-4 py-3 text-slate-300">
                                    {{ $booking->trip?->origin ?? '—' }} → {{ $booking->trip?->destination ?? '—' }}
                                </td>
                                <td class="px-4 py-3 text-slate-300">{{ $booking->seats }}</td>
                                <td class="px-4 py-3 text-slate-300">{{ number_format($booking->total_price, 2) }} JD</td>
                                <td class="px-4 py-3">@include('admin._partials.status_badge', ['status' => $booking->status])</td>
                                <td class="px-4 py-3 text-xs text-slate-500">{{ $booking->created_at->diffForHumans() }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
    </div>
@endsection
