<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ApiTokenAuth
{
    public function handle(Request $request, Closure $next, ?string $role = null): Response
    {
        $authHeader = $request->bearerToken() ?? $request->input('token');

        $user = User::findByApiToken($authHeader);

        if (!$user) {
            return response()->json([
                'status'  => false,
                'message' => 'Unauthenticated.',
            ], 401);
        }

        if (!$user->is_active) {
            return response()->json([
                'status'  => false,
                'message' => 'Account is not active.',
            ], 403);
        }

        if ($role && $user->role !== $role) {
            return response()->json([
                'status'  => false,
                'message' => 'Forbidden for this role.',
            ], 403);
        }

        $request->setUserResolver(fn () => $user);

        return $next($request);
    }
}
