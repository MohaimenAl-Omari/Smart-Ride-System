<!DOCTYPE html>
<html lang="en" class="h-full bg-slate-950">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Admin') · Smart Ride</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: { sans: ['Inter', 'sans-serif'] },
                    colors: {
                        ink: '#0A0A14',
                        panel: '#0F1020',
                        accent: '#6366F1',
                        accent2: '#06B6D4',
                    }
                }
            }
        }
    </script>
    <style>
        body { font-family: 'Inter', sans-serif; }
        .bg-grid {
            background-image:
                radial-gradient(circle at 20% 0%, rgba(99,102,241,0.18), transparent 40%),
                radial-gradient(circle at 80% 100%, rgba(6,182,212,0.14), transparent 40%);
        }
        .nav-link.active {
            background: linear-gradient(135deg, rgba(99,102,241,0.25), rgba(6,182,212,0.18));
            color: #fff;
            border-color: rgba(99,102,241,0.45);
        }
        .nav-link.active .nav-icon {
            color: #a5b4fc;
        }
    </style>
</head>
<body class="h-full text-slate-100 antialiased bg-grid">
@auth
    @if(auth()->user()->role === 'admin')
        <div class="min-h-full flex">
            <aside class="w-64 shrink-0 border-r border-white/5 bg-slate-950/70 backdrop-blur px-4 py-6 hidden md:flex md:flex-col">
                <a href="{{ route('admin.dashboard') }}" class="flex items-center gap-3 px-2 mb-8">
                    <span class="grid h-10 w-10 place-items-center rounded-xl bg-gradient-to-br from-indigo-500 to-cyan-500 font-bold shadow-lg shadow-indigo-500/30">
                        <svg class="w-5 h-5 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M14 16H9m10 0h3v-3.15a1 1 0 0 0-.84-.99L16 11l-2.7-3.6a1 1 0 0 0-.8-.4H5.24a2 2 0 0 0-1.8 1.1l-.8 1.63A6 6 0 0 0 2 12.42V16h2"/><circle cx="6.5" cy="16.5" r="2.5"/><circle cx="16.5" cy="16.5" r="2.5"/></svg>
                    </span>
                    <div>
                        <div class="text-base font-bold tracking-tight leading-none">Smart Ride</div>
                        <div class="text-[11px] uppercase tracking-widest text-indigo-300/70 mt-1">Admin Console</div>
                    </div>
                </a>

                <nav class="space-y-1 text-sm">
                    @php
                        $links = [
                            ['route' => 'admin.dashboard',       'label' => 'Overview',          'icon' => 'home'],
                            ['route' => 'admin.drivers.pending', 'label' => 'Pending Drivers',   'icon' => 'badge'],
                            ['route' => 'admin.users',           'label' => 'Users',             'icon' => 'users'],
                            ['route' => 'admin.trips',           'label' => 'Trips',             'icon' => 'route'],
                            ['route' => 'admin.bookings',        'label' => 'Bookings',          'icon' => 'ticket'],
                            ['route' => 'admin.contact',         'label' => 'Reports',           'icon' => 'mail'],
                        ];
                    @endphp

                    @foreach($links as $link)
                        @php $active = request()->routeIs($link['route']); @endphp
                        <a href="{{ route($link['route']) }}"
                           class="nav-link {{ $active ? 'active' : '' }} flex items-center gap-3 rounded-xl border border-transparent px-3 py-2.5 text-slate-400 hover:bg-white/5 hover:text-white transition">
                            <span class="nav-icon w-4 h-4 text-slate-500">
                                @switch($link['icon'])
                                    @case('home')   <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 12l9-9 9 9M5 10v10h14V10"/></svg> @break
                                    @case('badge')  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M6 22v-4a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v4"/></svg> @break
                                    @case('users')  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/></svg> @break
                                    @case('route')  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="6" cy="19" r="3"/><path d="M9 19h8.5a3.5 3.5 0 0 0 0-7h-11a3.5 3.5 0 0 1 0-7H15"/><circle cx="18" cy="5" r="3"/></svg> @break
                                    @case('ticket')<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 7a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v3a2 2 0 0 0 0 4v3a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-3a2 2 0 0 0 0-4z"/><path d="M13 5v2m0 4v2m0 4v2"/></svg> @break
                                    @case('mail')  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z"/><path d="m22 6-10 7L2 6"/></svg> @break
                                @endswitch
                            </span>
                            <span class="font-medium">{{ $link['label'] }}</span>
                        </a>
                    @endforeach
                </nav>

                <div class="mt-auto pt-6">
                    <div class="rounded-xl border border-white/5 bg-white/5 p-3">
                        <div class="flex items-center gap-3">
                            <div class="grid h-9 w-9 place-items-center rounded-lg bg-gradient-to-br from-indigo-500 to-cyan-500 text-sm font-bold">
                                {{ strtoupper(substr(auth()->user()->name, 0, 1)) }}
                            </div>
                            <div class="min-w-0">
                                <div class="text-sm font-semibold truncate">{{ auth()->user()->name }}</div>
                                <div class="text-[11px] text-slate-400 truncate">{{ auth()->user()->email }}</div>
                            </div>
                        </div>
                        <form action="{{ route('admin.logout') }}" method="POST" class="mt-3">
                            @csrf
                            <button class="w-full rounded-lg border border-white/10 bg-white/5 px-3 py-1.5 text-xs text-slate-200 hover:bg-white/10">
                                Sign out
                            </button>
                        </form>
                    </div>
                </div>
            </aside>

            <main class="flex-1 min-w-0">
                <header class="md:hidden flex items-center justify-between px-5 py-4 border-b border-white/5 bg-slate-950/60 backdrop-blur sticky top-0 z-10">
                    <a href="{{ route('admin.dashboard') }}" class="flex items-center gap-2">
                        <span class="grid h-8 w-8 place-items-center rounded-lg bg-gradient-to-br from-indigo-500 to-cyan-500 text-xs font-bold">SR</span>
                        <span class="font-semibold">Smart Ride · Admin</span>
                    </a>
                    <form action="{{ route('admin.logout') }}" method="POST">
                        @csrf
                        <button class="rounded-lg border border-white/10 bg-white/5 px-3 py-1.5 text-xs text-slate-200">Sign out</button>
                    </form>
                </header>

                <div class="px-5 md:px-10 py-8">
                    @if(session('status'))
                        <div class="mb-6 rounded-xl border border-emerald-500/20 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-200">
                            {{ session('status') }}
                        </div>
                    @endif
                    @yield('content')
                </div>
            </main>
        </div>
    @else
        <main class="px-6 py-10 max-w-6xl mx-auto">
            @yield('content')
        </main>
    @endif
@else
    <main class="min-h-screen flex items-center justify-center px-6 py-10">
        @yield('content')
    </main>
@endauth
</body>
</html>
