<?php

namespace Tests\Feature;

use App\Models\User;
use Tests\TestCase;

class AuthTest extends TestCase
{
    // ──────────────────────────────────────────────────────────────
    // POST /api/register
    // ──────────────────────────────────────────────────────────────

    public function test_passenger_can_register(): void
    {
        $response = $this->postJson('/api/register', [
            'name'     => 'Ali Hassan',
            'email'    => 'ali@example.com',
            'phone'    => '0790001111',
            'password' => 'secret123',
            'role'     => 'passenger',
        ]);

        $response->assertStatus(200)
            ->assertJson(['status' => true])
            ->assertJsonPath('user.role', 'passenger');

        $this->assertDatabaseHas('users', ['email' => 'ali@example.com']);
    }

    public function test_driver_registration_is_inactive_by_default(): void
    {
        $response = $this->postJson('/api/register', [
            'name'     => 'Sami Driver',
            'email'    => 'sami@example.com',
            'phone'    => '0790002222',
            'password' => 'secret123',
            'role'     => 'driver',
        ]);

        $response->assertStatus(200)
            ->assertJson(['status' => true, 'token' => '']);

        $this->assertDatabaseHas('users', [
            'email'     => 'sami@example.com',
            'is_active' => false,
        ]);
    }

    public function test_register_fails_with_duplicate_email(): void
    {
        $this->makePassenger(['email' => 'dup@example.com']);

        $response = $this->postJson('/api/register', [
            'name'     => 'Another',
            'email'    => 'dup@example.com',
            'phone'    => '0790003333',
            'password' => 'secret123',
        ]);

        $response->assertStatus(400)
            ->assertJson(['status' => false]);
    }

    public function test_register_fails_without_required_fields(): void
    {
        $response = $this->postJson('/api/register', []);

        $response->assertStatus(400)
            ->assertJson(['status' => false]);
    }

    // ──────────────────────────────────────────────────────────────
    // POST /api/login
    // ──────────────────────────────────────────────────────────────

    public function test_passenger_can_login(): void
    {
        $this->makePassenger(['email' => 'login@example.com', 'password' => bcrypt('mypass')]);

        $response = $this->postJson('/api/login', [
            'email'    => 'login@example.com',
            'password' => 'mypass',
        ]);

        $response->assertStatus(200)
            ->assertJson(['status' => true])
            ->assertJsonStructure(['token', 'user']);
    }

    public function test_login_fails_with_wrong_password(): void
    {
        $this->makePassenger(['email' => 'login2@example.com', 'password' => bcrypt('correct')]);

        $response = $this->postJson('/api/login', [
            'email'    => 'login2@example.com',
            'password' => 'wrong',
        ]);

        $response->assertStatus(401)
            ->assertJson(['status' => false, 'message' => 'Invalid credentials']);
    }

    public function test_inactive_driver_cannot_login(): void
    {
        $this->makeDriver([
            'email'     => 'inactive@example.com',
            'password'  => bcrypt('pass'),
            'is_active' => false,
        ]);

        $response = $this->postJson('/api/login', [
            'email'    => 'inactive@example.com',
            'password' => 'pass',
        ]);

        $response->assertStatus(403);
    }

    public function test_login_fails_without_fields(): void
    {
        $response = $this->postJson('/api/login', []);

        $response->assertStatus(400)
            ->assertJson(['status' => false]);
    }

    // ──────────────────────────────────────────────────────────────
    // POST /api/logout
    // ──────────────────────────────────────────────────────────────

    public function test_authenticated_user_can_logout(): void
    {
        $user    = $this->makePassenger();
        $headers = $this->headersFor($user);

        $response = $this->postJson('/api/logout', [], $headers);

        $response->assertStatus(200)
            ->assertJson(['status' => true]);

        // Token should be wiped — subsequent request must fail
        $this->getJson('/api/me', $headers)->assertStatus(401);
    }

    public function test_unauthenticated_logout_returns_401(): void
    {
        $response = $this->postJson('/api/logout');

        $response->assertStatus(401);
    }

    // ──────────────────────────────────────────────────────────────
    // GET /api/me
    // ──────────────────────────────────────────────────────────────

    public function test_me_returns_authenticated_user(): void
    {
        $user    = $this->makePassenger(['email' => 'me@example.com']);
        $headers = $this->headersFor($user);

        $response = $this->getJson('/api/me', $headers);

        $response->assertStatus(200)
            ->assertJson(['status' => true])
            ->assertJsonPath('user.email', 'me@example.com');
    }

    public function test_me_requires_authentication(): void
    {
        $response = $this->getJson('/api/me');

        $response->assertStatus(401);
    }

    // ──────────────────────────────────────────────────────────────
    // POST /api/profile
    // ──────────────────────────────────────────────────────────────

    public function test_user_can_update_name_and_city(): void
    {
        $user    = $this->makePassenger();
        $headers = $this->headersFor($user);

        $response = $this->postJson('/api/profile', [
            'name' => 'Updated Name',
            'city' => 'Zarqa',
        ], $headers);

        $response->assertStatus(200)
            ->assertJson(['status' => true])
            ->assertJsonPath('user.name', 'Updated Name')
            ->assertJsonPath('user.city', 'Zarqa');
    }

    public function test_user_can_change_password(): void
    {
        $user    = $this->makePassenger(['password' => bcrypt('oldpass')]);
        $headers = $this->headersFor($user);

        $response = $this->postJson('/api/profile', [
            'password'         => 'newpass123',
            'current_password' => 'oldpass',
        ], $headers);

        $response->assertStatus(200)->assertJson(['status' => true]);
    }

    public function test_wrong_current_password_is_rejected(): void
    {
        $user    = $this->makePassenger(['password' => bcrypt('correct')]);
        $headers = $this->headersFor($user);

        $response = $this->postJson('/api/profile', [
            'password'         => 'newpass123',
            'current_password' => 'wrong',
        ], $headers);

        $response->assertStatus(400)
            ->assertJson(['status' => false]);
    }

    public function test_profile_update_requires_authentication(): void
    {
        $response = $this->postJson('/api/profile', ['name' => 'Nobody']);

        $response->assertStatus(401);
    }
}
