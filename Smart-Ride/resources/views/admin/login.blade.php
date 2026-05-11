@extends('admin.layout')

@section('title', 'Admin sign in')

@section('content')
    <div class="grid w-full max-w-5xl grid-cols-1 overflow-hidden rounded-3xl border border-white/10 bg-slate-950/50 shadow-2xl shadow-indigo-900/20 md:grid-cols-2">
        <div class="hidden bg-gradient-to-br from-indigo-600/30 via-slate-900 to-cyan-500/20 p-10 md:flex md:flex-col md:justify-between">
            <div class="flex items-center gap-3">
                <div class="grid h-11 w-11 place-items-center rounded-xl bg-gradient-to-br from-indigo-500 to-cyan-500 font-bold shadow-lg shadow-indigo-500/30">
                    <svg class="w-5 h-5 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M14 16H9m10 0h3v-3.15a1 1 0 0 0-.84-.99L16 11l-2.7-3.6a1 1 0 0 0-.8-.4H5.24a2 2 0 0 0-1.8 1.1l-.8 1.63A6 6 0 0 0 2 12.42V16h2"/><circle cx="6.5" cy="16.5" r="2.5"/><circle cx="16.5" cy="16.5" r="2.5"/></svg>
                </div>
                <div>
                    <div class="font-bold text-lg">Smart Ride</div>
                    <div class="text-[11px] uppercase tracking-widest text-indigo-200/70">Admin Console</div>
                </div>
            </div>

            <div>
                <h2 class="text-3xl font-bold leading-tight">Smart carpool<br>operations, simplified.</h2>
                <p class="mt-3 text-sm text-slate-300/80 max-w-md">
                    Approve drivers, monitor segmented routes, and oversee bookings — all from one secure dashboard.
                </p>

                <div class="mt-8 grid grid-cols-3 gap-3">
                    <div class="rounded-xl border border-white/10 bg-white/5 p-3">
                        <div class="text-2xl font-bold text-white">3</div>
                        <div class="text-[11px] uppercase tracking-wide text-slate-400">Roles</div>
                    </div>
                    <div class="rounded-xl border border-white/10 bg-white/5 p-3">
                        <div class="text-2xl font-bold text-white">∞</div>
                        <div class="text-[11px] uppercase tracking-wide text-slate-400">Segments</div>
                    </div>
                    <div class="rounded-xl border border-white/10 bg-white/5 p-3">
                        <div class="text-2xl font-bold text-white">24/7</div>
                        <div class="text-[11px] uppercase tracking-wide text-slate-400">Monitor</div>
                    </div>
                </div>
            </div>

            <div class="text-xs text-slate-500">© Smart Ride · Jordan University of Science and Technology</div>
        </div>

        <div class="p-10">
            <div class="mb-8">
                <h1 class="text-2xl font-semibold tracking-tight">Welcome back</h1>
                <p class="mt-1 text-sm text-slate-400">Sign in to manage Smart Ride.</p>
            </div>

            <form method="POST" action="{{ route('admin.login.submit') }}" class="space-y-4">
                @csrf

                <div>
                    <label class="mb-1.5 block text-xs font-medium uppercase tracking-wide text-slate-400" for="email">Email</label>
                    <input id="email" name="email" type="email" required autofocus
                           value="{{ old('email') }}"
                           placeholder="admin@smartride.app"
                           class="w-full rounded-lg border border-white/10 bg-slate-950/40 px-3 py-3 text-sm outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-500/20">
                    @error('email')
                        <p class="mt-1.5 text-xs text-rose-400">{{ $message }}</p>
                    @enderror
                </div>

                <div>
                    <label class="mb-1.5 block text-xs font-medium uppercase tracking-wide text-slate-400" for="password">Password</label>
                    <input id="password" name="password" type="password" required
                           placeholder="********"
                           class="w-full rounded-lg border border-white/10 bg-slate-950/40 px-3 py-3 text-sm outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-500/20">
                </div>

                <label class="flex items-center gap-2 text-xs text-slate-400">
                    <input type="checkbox" name="remember" value="1" class="h-4 w-4 rounded border-white/20 bg-slate-950/40">
                    Remember me on this device
                </label>

                <button type="submit"
                        class="w-full rounded-lg bg-gradient-to-r from-indigo-500 to-cyan-500 px-4 py-3 text-sm font-semibold shadow-lg shadow-indigo-500/30 hover:opacity-95 transition">
                    Sign in to dashboard
                </button>
            </form>

            <p class="mt-6 text-center text-[11px] text-slate-500">
                Admin access only. All sessions are logged.
            </p>
        </div>
    </div>
@endsection
