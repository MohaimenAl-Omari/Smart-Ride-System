@extends('admin.layout')

@section('title', 'Trips')

@section('content')
    <div class="mb-8">
        <div class="text-xs uppercase tracking-widest text-indigo-300/80">Operations</div>
        <h1 class="mt-1 text-3xl font-bold tracking-tight">Trips</h1>
        <p class="mt-1 text-sm text-slate-400">Monitor trips created by drivers across the platform.</p>
    </div>

    <form method="GET" action="{{ route('admin.trips') }}"
          class="mb-6 flex flex-wrap gap-3 rounded-2xl border border-white/10 bg-white/[0.04] p-3">
        <div class="relative flex-1 min-w-[200px]">
            <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            <input name="q" value="{{ $search }}" placeholder="Search by city / route..."
                   class="w-full rounded-lg border border-white/10 bg-slate-950/40 pl-9 pr-3 py-2 text-sm outline-none focus:border-indigo-400">
        </div>

        <div class="flex flex-wrap gap-1 rounded-lg border border-white/10 bg-slate-950/40 p-1">
            @foreach (['all' => 'All', 'scheduled' => 'Scheduled', 'in_progress' => 'In progress', 'completed' => 'Completed', 'cancelled' => 'Cancelled'] as $value => $label)
                <a href="{{ route('admin.trips', ['status' => $value, 'q' => $search]) }}"
                   class="rounded-md px-3 py-1.5 text-xs font-medium transition
                          {{ $status === $value ? 'bg-gradient-to-r from-indigo-500 to-cyan-500 text-white' : 'text-slate-400 hover:text-white' }}">
                    {{ $label }}
                </a>
            @endforeach
        </div>

        <button class="rounded-lg border border-white/10 bg-white/5 px-3 py-2 text-xs text-slate-200 hover:bg-white/10">Apply</button>
    </form>

    <div class="rounded-2xl border border-white/10 bg-white/[0.04] overflow-hidden">
        <table class="min-w-full divide-y divide-white/5 text-sm">
            <thead class="bg-white/[0.03] text-[11px] uppercase tracking-wide text-slate-400">
                <tr>
                    <th class="px-4 py-3 text-left font-medium">Route</th>
                    <th class="px-4 py-3 text-left font-medium">Driver</th>
                    <th class="px-4 py-3 text-left font-medium">Departure</th>
                    <th class="px-4 py-3 text-left font-medium">Seats</th>
                    <th class="px-4 py-3 text-left font-medium">Price</th>
                    <th class="px-4 py-3 text-left font-medium">Bookings</th>
                    <th class="px-4 py-3 text-left font-medium">Status</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-white/5">
                @forelse($trips as $trip)
                    <tr class="hover:bg-white/[0.02] cursor-pointer" onclick="window.location='{{ route('admin.trips.show', $trip) }}'">
                        <td class="px-4 py-3">
                            <div class="text-white font-medium">{{ $trip->origin }} → {{ $trip->destination }}</div>
                            <div class="text-[11px] text-slate-500">#{{ $trip->id }}</div>
                        </td>
                        <td class="px-4 py-3 text-slate-300">{{ $trip->driver?->name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-400 text-xs">{{ $trip->departure_at?->format('M d, Y H:i') }}</td>
                        <td class="px-4 py-3 text-slate-300">{{ $trip->seats_available }}/{{ $trip->seats_total }}</td>
                        <td class="px-4 py-3 text-slate-300">{{ number_format($trip->price_per_seat, 2) }} JD</td>
                        <td class="px-4 py-3 text-slate-300">{{ $trip->bookings_count }}</td>
                        <td class="px-4 py-3">@include('admin._partials.status_badge', ['status' => $trip->status])</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="7" class="px-4 py-12 text-center text-sm text-slate-400">No trips match your filters.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">{{ $trips->links() }}</div>
@endsection
