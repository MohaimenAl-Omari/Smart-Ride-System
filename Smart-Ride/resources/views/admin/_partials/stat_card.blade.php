@props(['label', 'value', 'color' => 'indigo', 'icon' => null, 'hint' => null])

@php
    $accent = [
        'indigo'  => 'from-indigo-500/30 to-indigo-500/0  text-indigo-300',
        'cyan'    => 'from-cyan-500/30   to-cyan-500/0    text-cyan-300',
        'emerald' => 'from-emerald-500/30 to-emerald-500/0 text-emerald-300',
        'amber'   => 'from-amber-500/30  to-amber-500/0   text-amber-300',
        'rose'    => 'from-rose-500/30   to-rose-500/0    text-rose-300',
    ][$color] ?? 'from-slate-500/30 to-slate-500/0 text-slate-300';
@endphp

<div class="relative overflow-hidden rounded-2xl border border-white/10 bg-white/[0.04] p-5">
    <div class="absolute inset-0 bg-gradient-to-br {{ $accent }} opacity-50 -z-10"></div>
    <div class="flex items-center justify-between">
        <div class="text-xs uppercase tracking-wider text-slate-400">{{ $label }}</div>
        @if($icon)
            <div class="grid h-8 w-8 place-items-center rounded-lg bg-white/5 text-slate-300">
                {!! $icon !!}
            </div>
        @endif
    </div>
    <div class="mt-2 text-3xl font-bold tracking-tight text-white">{{ $value }}</div>
    @if($hint)
        <div class="mt-1 text-[11px] text-slate-400">{{ $hint }}</div>
    @endif
</div>
