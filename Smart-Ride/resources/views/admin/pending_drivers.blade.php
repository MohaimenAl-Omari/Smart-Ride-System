@extends('admin.layout')

@section('title', 'Pending drivers')

@section('content')
    <div class="mb-8 flex items-end justify-between">
        <div>
            <div class="text-xs uppercase tracking-widest text-indigo-300/80">Verification queue</div>
            <h1 class="mt-1 text-3xl font-bold tracking-tight">Pending drivers</h1>
            <p class="mt-1 text-sm text-slate-400">
                {{ $pendingDrivers->count() }}
                {{ Str::plural('application', $pendingDrivers->count()) }} awaiting review.
            </p>
        </div>
    </div>

    @if($pendingDrivers->isEmpty())
        <div class="rounded-2xl border border-white/10 bg-white/5 px-6 py-20 text-center">
            <div class="mx-auto grid h-12 w-12 place-items-center rounded-xl bg-emerald-500/15 text-emerald-300">
                <svg class="w-6 h-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
            </div>
            <p class="mt-3 text-slate-200">All caught up.</p>
            <p class="mt-1 text-xs text-slate-500">New driver signups will appear here automatically.</p>
        </div>
    @else
        <div class="space-y-4">
            @foreach($pendingDrivers as $driver)
                <div class="rounded-2xl border border-white/10 bg-white/[0.04] p-5">
                    <div class="flex flex-wrap items-start justify-between gap-4">
                        <div>
                            <div class="flex items-center gap-3">
                                <div class="grid h-11 w-11 place-items-center rounded-xl bg-gradient-to-br from-indigo-500 to-cyan-500 font-semibold">
                                    {{ strtoupper(substr($driver->name, 0, 1)) }}
                                </div>
                                <div>
                                    <div class="font-semibold text-white">{{ $driver->name }}</div>
                                    <div class="text-xs text-slate-400">
                                        {{ $driver->email }} · {{ $driver->phone }}
                                    </div>
                                </div>
                            </div>
                            <div class="mt-3 text-xs text-slate-500">
                                Submitted {{ $driver->created_at->diffForHumans() }}
                            </div>
                        </div>

                        <div class="flex gap-2">
                            <form method="POST" action="{{ route('admin.drivers.approve', $driver) }}">
                                @csrf
                                <button class="rounded-lg bg-emerald-500/90 px-4 py-2 text-sm font-semibold text-slate-950 hover:bg-emerald-400 transition">
                                    Approve
                                </button>
                            </form>
                            <form method="POST" action="{{ route('admin.drivers.reject', $driver) }}"
                                  onsubmit="return confirm('Reject this driver? Their account and uploaded documents will be deleted.');">
                                @csrf
                                <button class="rounded-lg border border-rose-500/40 bg-rose-500/10 px-4 py-2 text-sm font-semibold text-rose-300 hover:bg-rose-500/20 transition">
                                    Reject
                                </button>
                            </form>
                        </div>
                    </div>

                    <div class="mt-5 grid grid-cols-1 gap-3 sm:grid-cols-3">
                        @php
                            $docs = [
                                'license'        => 'Driving license',
                                'non_conviction' => 'Non-conviction certificate',
                                'medical'        => 'Medical certificate',
                            ];
                            $cert = $driver->certificate;
                            $fieldMap = [
                                'license'        => 'license_path',
                                'non_conviction' => 'non_conviction_path',
                                'medical'        => 'medical_path',
                            ];
                        @endphp

                        @foreach($docs as $type => $label)
                            @php $hasFile = $cert && $cert->{$fieldMap[$type]}; @endphp
                            <div class="rounded-xl border border-white/10 bg-slate-950/40 p-3">
                                <div class="text-[11px] uppercase tracking-wide text-slate-500">{{ $label }}</div>
                                @if($hasFile)
                                    <a href="{{ route('admin.drivers.certificate', [$driver, $type]) }}" target="_blank"
                                       class="mt-1 inline-flex items-center gap-1.5 text-sm text-cyan-400 hover:text-cyan-300">
                                        View file
                                        <span aria-hidden="true">↗</span>
                                    </a>
                                @else
                                    <div class="mt-1 text-sm text-slate-500">Not uploaded</div>
                                @endif
                            </div>
                        @endforeach
                    </div>
                </div>
            @endforeach
        </div>
    @endif
@endsection
