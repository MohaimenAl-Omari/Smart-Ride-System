<?php

namespace Tests;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    use RefreshDatabase;

    /**
     * Return request headers that authenticate as the given user.
     */
    protected function headersFor(User $user): array
    {
        $token = $user->refreshApiToken();
        return ['Authorization' => "Bearer {$token}"];
    }

    /**
     * Create an active passenger user.
     */
    protected function makePassenger(array $overrides = []): User
    {
        return User::create(array_merge([
            'name'        => 'Test Passenger',
            'email'       => 'passenger@test.com',
            'phone'       => '0790000001',
            'password'    => bcrypt('password'),
            'role'        => 'passenger',
            'is_active'   => true,
            'is_verified' => false,
            'balance'     => 0,
        ], $overrides));
    }

    /**
     * Create an active driver user.
     */
    protected function makeDriver(array $overrides = []): User
    {
        return User::create(array_merge([
            'name'        => 'Test Driver',
            'email'       => 'driver@test.com',
            'phone'       => '0790000002',
            'password'    => bcrypt('password'),
            'role'        => 'driver',
            'is_active'   => true,
            'is_verified' => true,
            'balance'     => 0,
        ], $overrides));
    }

    /**
     * Build a minimal valid trip payload for POST /api/driver/trips.
     */
    protected function tripPayload(array $overrides = []): array
    {
        return array_merge([
            'origin'         => 'Irbid',
            'destination'    => 'Amman',
            'departure_at'   => now()->addDay()->format('Y-m-d H:i:s'),
            'seats_total'    => 4,
            'segment_prices' => [10.00],
        ], $overrides);
    }
}
