@extends('admin.layout')

@section('title', 'Trip #' . $trip->id)

@section('content')
    <div class="mb-6">
        <a href="{{ route('admin.trips') }}" class="text-xs text-cyan-300 hover:text-cyan-200">← Back to trips</a>
    </div>

    <div class="rounded-2xl border border-white/10 bg-white/[0.04] p-6 mb-6">
        <div class="flex flex-wrap items-start justify-between gap-4">
            <div>
                <div class="text-xs uppercase tracking-widest text-indigo-300/80">Trip #{{ $trip->id }}</div>
                <h1 class="mt-1 text-2xl font-bold tracking-tight">{{ $trip->origin }} → {{ $trip->destination }}</h1>
                <p class="mt-1 text-sm text-slate-400">
                    Driver: {{ $trip->driver?->name }} · {{ $trip->driver?->phone }}
                </p>
            </div>
            <div>@include('admin._partials.status_badge', ['status' => $trip->status])</div>
        </div>

        <div class="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
            <div class="rounded-xl border border-white/10 bg-slate-950/40 p-3">
                <div class="text-[11px] uppercase tracking-wide text-slate-500">Departure</div>
                <div class="mt-1 text-sm text-white">{{ $trip->departure_at?->format('M d, Y') }}</div>
                <div class="text-[11px] text-slate-400">{{ $trip->departure_at?->format('H:i') }}</div>
            </div>
            <div class="rounded-xl border border-white/10 bg-slate-950/40 p-3">
                <div class="text-[11px] uppercase tracking-wide text-slate-500">Seats</div>
                <div class="mt-1 text-sm text-white">{{ $trip->seats_available }} / {{ $trip->seats_total }}</div>
                <div class="text-[11px] text-slate-400">Min {{ $trip->min_passengers }}</div>
            </div>
            <div class="rounded-xl border border-white/10 bg-slate-950/40 p-3">
                <div class="text-[11px] uppercase tracking-wide text-slate-500">Price / seat</div>
                <div class="mt-1 text-sm text-white">{{ number_format($trip->price_per_seat, 2) }} JD</div>
            </div>
            <div class="rounded-xl border border-white/10 bg-slate-950/40 p-3">
                <div class="text-[11px] uppercase tracking-wide text-slate-500">Vehicle</div>
                <div class="mt-1 text-sm text-white">{{ $trip->car_model ?? '—' }}</div>
                <div class="text-[11px] text-slate-400">{{ $trip->car_plate ?? '—' }}</div>
            </div>
        </div>

        @if($trip->stops->isNotEmpty())
            <div class="mt-6">
                <div class="text-xs uppercase tracking-widest text-indigo-300/80 mb-2">Segmented route</div>
                <div class="flex flex-wrap items-center gap-2">
                    @foreach($trip->stops as $i => $stop)
                        <div class="rounded-lg border border-white/10 bg-slate-950/40 px-3 py-1.5 text-sm text-white">
                            {{ $stop->name }}
                        </div>
                        @if($i < $trip->stops->count() - 1)
                            <span class="text-slate-500">→</span>
                        @endif
                    @endforeach
                </div>
            </div>
        @endif
    </div>

    <div class="rounded-2xl border border-white/10 bg-white/[0.04] p-6">
        <h2 class="mb-4 text-base font-semibold">Bookings</h2>
        @if($trip->bookings->isEmpty())
            <div class="rounded-xl border border-white/10 bg-slate-950/40 px-4 py-10 text-center text-sm text-slate-400">
                No passengers have booked this trip yet.
            </div>
        @else
            <div class="overflow-hidden rounded-xl border border-white/10">
                <table class="min-w-full divide-y divide-white/5 text-sm">
                    <thead class="bg-white/[0.03] text-[11px] uppercase tracking-wide text-slate-400">
                        <tr>
                            <th class="px-4 py-3 text-left font-medium">Passenger</th>
                            <th class="px-4 py-3 text-left font-medium">Pickup → Drop-off</th>
                            <th class="px-4 py-3 text-left font-medium">Seats</th>
                            <th class="px-4 py-3 text-left font-medium">Total</th>
                            <th class="px-4 py-3 text-left font-medium">Status</th>
                            <th class="px-4 py-3 text-left font-medium">Date</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-white/5">
                        @foreach($trip->bookings as $booking)
                            <tr class="hover:bg-white/[0.02]">
                                <td class="px-4 py-3 text-white">{{ $booking->passenger?->name }}</td>
                                <td class="px-4 py-3 text-slate-300">{{ $booking->pickup_stop }} → {{ $booking->dropoff_stop }}</td>
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
