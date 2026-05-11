@extends('admin.layout')

@section('title', 'Reports')

@section('content')
    <div class="mb-8">
        <div class="text-xs uppercase tracking-widest text-indigo-300/80">Support</div>
        <h1 class="mt-1 text-3xl font-bold tracking-tight">User Reports</h1>
        <p class="mt-1 text-sm text-slate-400">
            Inbound "Contact us" messages from passengers and drivers.
        </p>
    </div>

    {{-- Counters --}}
    <div class="mb-6 grid gap-3 sm:grid-cols-3">
        <div class="rounded-2xl border border-rose-500/20 bg-rose-500/5 p-4">
            <div class="text-xs uppercase tracking-wide text-rose-300/80">New</div>
            <div class="mt-1 text-2xl font-bold">{{ $counts['new'] }}</div>
        </div>
        <div class="rounded-2xl border border-amber-500/20 bg-amber-500/5 p-4">
            <div class="text-xs uppercase tracking-wide text-amber-300/80">In progress</div>
            <div class="mt-1 text-2xl font-bold">{{ $counts['in_progress'] }}</div>
        </div>
        <div class="rounded-2xl border border-emerald-500/20 bg-emerald-500/5 p-4">
            <div class="text-xs uppercase tracking-wide text-emerald-300/80">Resolved</div>
            <div class="mt-1 text-2xl font-bold">{{ $counts['resolved'] }}</div>
        </div>
    </div>

    {{-- Filters --}}
    <form method="GET" action="{{ route('admin.contact') }}"
          class="mb-6 flex flex-wrap gap-3 rounded-2xl border border-white/10 bg-white/[0.04] p-3">
        <div class="relative flex-1 min-w-[200px]">
            <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500"
                 viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="11" cy="11" r="8"/>
                <path d="m21 21-4.3-4.3"/>
            </svg>
            <input name="q" value="{{ $search }}"
                   placeholder="Search subject, message or email..."
                   class="w-full rounded-lg border border-white/10 bg-slate-950/40 pl-9 pr-3 py-2 text-sm outline-none focus:border-indigo-400">
        </div>

        <div class="flex gap-1 rounded-lg border border-white/10 bg-slate-950/40 p-1">
            @foreach (['all' => 'All', 'new' => 'New', 'in_progress' => 'In progress', 'resolved' => 'Resolved'] as $value => $label)
                <a href="{{ route('admin.contact', ['status' => $value, 'q' => $search]) }}"
                   class="rounded-md px-3 py-1.5 text-xs font-medium transition
                          {{ $status === $value ? 'bg-gradient-to-r from-indigo-500 to-cyan-500 text-white' : 'text-slate-400 hover:text-white' }}">
                    {{ $label }}
                </a>
            @endforeach
        </div>

        <button class="rounded-lg border border-white/10 bg-white/5 px-3 py-2 text-xs text-slate-200 hover:bg-white/10">
            Apply
        </button>
    </form>

    {{-- List --}}
    <div class="space-y-3">
        @forelse($messages as $message)
            <div class="rounded-2xl border border-white/10 bg-white/[0.04] p-5">
                <div class="flex flex-wrap items-start justify-between gap-3">
                    <div class="min-w-0 flex-1">
                        <div class="flex items-center gap-2 text-xs text-slate-400">
                            <span>#{{ $message->id }}</span>
                            <span>·</span>
                            <span>{{ $message->created_at->diffForHumans() }}</span>
                            @if($message->user)
                                <span>·</span>
                                <span class="text-slate-300">{{ $message->user->name }}</span>
                                <span class="rounded-full bg-white/5 px-2 py-0.5 text-[10px] uppercase tracking-wide text-slate-300">
                                    {{ $message->user->role }}
                                </span>
                            @endif
                        </div>
                        <h3 class="mt-1 text-base font-semibold text-white">
                            {{ $message->subject }}
                        </h3>
                        <p class="mt-2 whitespace-pre-line text-sm text-slate-300">
                            {{ $message->message }}
                        </p>
                        <div class="mt-3 flex flex-wrap items-center gap-3 text-xs">
                            <a href="mailto:{{ $message->email }}" class="text-cyan-300 hover:underline">
                                {{ $message->email }}
                            </a>
                        </div>
                    </div>

                    <div class="flex flex-col items-end gap-3">
                        @include('admin._partials.status_badge', ['status' => $message->status])

                        <form method="POST"
                              action="{{ route('admin.contact.update', $message) }}"
                              class="flex items-center gap-2">
                            @csrf
                            <select name="status"
                                    class="rounded-lg border border-white/10 bg-slate-950/40 px-2 py-1.5 text-xs text-slate-200 outline-none focus:border-indigo-400">
                                @foreach (['new' => 'New', 'in_progress' => 'In progress', 'resolved' => 'Resolved'] as $key => $label)
                                    <option value="{{ $key }}" @selected($message->status === $key)>{{ $label }}</option>
                                @endforeach
                            </select>
                            <button class="rounded-lg bg-gradient-to-r from-indigo-500 to-cyan-500 px-3 py-1.5 text-xs font-semibold text-white hover:opacity-90">
                                Update
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        @empty
            <div class="rounded-2xl border border-white/10 bg-white/[0.04] p-10 text-center text-sm text-slate-400">
                No messages match your filters.
            </div>
        @endforelse
    </div>

    <div class="mt-4">{{ $messages->links() }}</div>
@endsection
