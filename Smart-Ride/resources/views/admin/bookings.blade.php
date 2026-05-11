@extends('admin.layout')

@section('title', 'Bookings')

@section('content')
    <div class="mb-8">
        <div class="text-xs uppercase tracking-widest text-indigo-300/80">Operations</div>
        <h1 class="mt-1 text-3xl font-bold tracking-tight">Bookings</h1>
        <p class="mt-1 text-sm text-slate-400">Every booking made through Smart Ride.</p>
    </div>

    <div class="mb-6 flex flex-wrap gap-1 rounded-2xl border border-white/10 bg-white/[0.04] p-1">
        @foreach (['all' => 'All', 'pending' => 'Pending', 'accepted' => 'Accepted', 'rejected' => 'Rejected', 'cancelled' => 'Cancelled', 'completed' => 'Completed'] as $value => $label)
            <a href="{{ route('admin.bookings', ['status' => $value]) }}"
               class="rounded-md px-3 py-1.5 text-xs font-medium transition
                      {{ $status === $value ? 'bg-gradient-to-r from-indigo-500 to-cyan-500 text-white' : 'text-slate-400 hover:text-white' }}">
                {{ $label }}
            </a>
        @endforeach
    </div>

    <div class="rounded-2xl border border-white/10 bg-white/[0.04] overflow-hidden">
        <table class="min-w-full divide-y divide-white/5 text-sm">
            <thead class="bg-white/[0.03] text-[11px] uppercase tracking-wide text-slate-400">
                <tr>
                    <th class="px-4 py-3 text-left font-medium">#</th>
                    <th class="px-4 py-3 text-left font-medium">Passenger</th>
                    <th class="px-4 py-3 text-left font-medium">Trip</th>
                    <th class="px-4 py-3 text-left font-medium">Driver</th>
                    <th class="px-4 py-3 text-left font-medium">Seats</th>
                    <th class="px-4 py-3 text-left font-medium">Total</th>
                    <th class="px-4 py-3 text-left font-medium">Status</th>
                    <th class="px-4 py-3 text-left font-medium">Date</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-white/5">
                @forelse($bookings as $booking)
                    <tr class="hover:bg-white/[0.02]">
                        <td class="px-4 py-3 text-slate-500">#{{ $booking->id }}</td>
                        <td class="px-4 py-3 text-white">{{ $booking->passenger?->name }}</td>
                        <td class="px-4 py-3 text-slate-300">
                            @if($booking->trip)
                                <a href="{{ route('admin.trips.show', $booking->trip) }}" class="hover:text-cyan-300">
                                    {{ $booking->trip->origin }} → {{ $booking->trip->destination }}
                                </a>
                            @else
                                —
                            @endif
                        </td>
                        <td class="px-4 py-3 text-slate-300">{{ $booking->trip?->driver?->name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-300">{{ $booking->seats }}</td>
                        <td class="px-4 py-3 text-slate-300">{{ number_format($booking->total_price, 2) }} JD</td>
                        <td class="px-4 py-3">@include('admin._partials.status_badge', ['status' => $booking->status])</td>
                        <td class="px-4 py-3 text-xs text-slate-500">{{ $booking->created_at->diffForHumans() }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="8" class="px-4 py-12 text-center text-sm text-slate-400">No bookings match your filters.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">{{ $bookings->links() }}</div>
@endsection
