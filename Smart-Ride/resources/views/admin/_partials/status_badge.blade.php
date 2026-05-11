@props(['status'])

@php
    $map = [
        'pending'     => ['bg' => 'bg-amber-500/15',   'text' => 'text-amber-300',   'label' => 'Pending'],
        'accepted'    => ['bg' => 'bg-emerald-500/15', 'text' => 'text-emerald-300', 'label' => 'Accepted'],
        'rejected'    => ['bg' => 'bg-rose-500/15',    'text' => 'text-rose-300',    'label' => 'Rejected'],
        'cancelled'   => ['bg' => 'bg-slate-500/15',   'text' => 'text-slate-300',   'label' => 'Cancelled'],
        'completed'   => ['bg' => 'bg-cyan-500/15',    'text' => 'text-cyan-300',    'label' => 'Completed'],
        'scheduled'   => ['bg' => 'bg-indigo-500/15',  'text' => 'text-indigo-300',  'label' => 'Scheduled'],
        'in_progress' => ['bg' => 'bg-emerald-500/15', 'text' => 'text-emerald-300', 'label' => 'In progress'],
        'new'         => ['bg' => 'bg-rose-500/15',    'text' => 'text-rose-300',    'label' => 'New'],
        'resolved'    => ['bg' => 'bg-emerald-500/15', 'text' => 'text-emerald-300', 'label' => 'Resolved'],
    ];
    $s = $map[$status] ?? ['bg' => 'bg-slate-500/15', 'text' => 'text-slate-300', 'label' => ucfirst($status)];
@endphp

<span class="inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-[11px] font-medium {{ $s['bg'] }} {{ $s['text'] }}">
    <span class="h-1.5 w-1.5 rounded-full bg-current"></span>
    {{ $s['label'] }}
</span>
