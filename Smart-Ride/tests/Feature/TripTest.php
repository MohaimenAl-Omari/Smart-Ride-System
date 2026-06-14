<?php

namespace Tests\Feature;

use App\Models\Booking;
use App\Models\Trip;
use App\Models\User;
use Tests\TestCase;

class TripTest extends TestCase
{
    // ──────────────────────────────────────────────────────────────
    // POST /api/driver/trips
    // ──────────────────────────────────────────────────────────────

    public function test_driver_can_create_trip(): void
    {
        $driver  = $this->makeDriver();
        $headers = $this->headersFor($driver);

        $response = $this->postJson('/api/driver/trips', $this->tripPayload(), $headers);

        $response->assertStatus(200)
            ->assertJson(['status' => true])
            ->assertJsonPath('trip.origin', 'Irbid')
            ->assertJsonPath('trip.destination', 'Amman')
            ->assertJsonStructure(['trip' => ['id', 'segments', 'stops']]);

        $this->assertDatabaseHas('trips', [
            'driver_id'   => $driver->id,
            'origin'      => 'Irbid',
            'destination' => 'Amman',
            'status'      => 'scheduled',
        ]);
    }

    public function test_passenger_cannot_create_trip(): void
    {
        $passenger = $this->makePassenger();
        $headers   = $this->headersFor($passenger);

        $response = $this->postJson('/api/driver/trips', $this->tripPayload(), $headers);

        $response->assertStatus(403);
    }

    public function test_trip_creation_requires_authentication(): void
    {
        $response = $this->postJson('/api/driver/trips', $this->tripPayload());

        $response->assertStatus(401);
    }

    public function test_trip_creation_fails_without_required_fields(): void
    {
        $driver  = $this->makeDriver();
        $headers = $this->headersFor($driver);

        $response = $this->postJson('/api/driver/trips', [], $headers);

        $response->assertStatus(400)->assertJson(['status' => false]);
    }

    public function test_trip_creation_fails_with_past_departure(): void
    {
        $driver  = $this->makeDriver();
        $headers = $this->headersFor($driver);

        $payload = $this->tripPayload(['departure_at' => now()->subHour()->format('Y-m-d H:i:s')]);

        $response = $this->postJson('/api/driver/trips', $payload, $headers);

        $response->assertStatus(400)->assertJson(['status' => false]);
    }

    public function test_trip_is_created_with_correct_segments(): void
    {
        $driver  = $this->makeDriver();
        $headers = $this->headersFor($driver);

        $payload = $this->tripPayload([
            'stops'          => ['Zarqa'],
            'segment_prices' => [5.00, 8.00],
        ]);

        $response = $this->postJson('/api/driver/trips', $payload, $headers);

        $response->assertStatus(200);
        $trip = Trip::find($response->json('trip.id'));
        $this->assertCount(2, $trip->segments);
        $this->assertEquals(13.00, (float) $trip->price_per_seat); // sum of segments
    }

    // ──────────────────────────────────────────────────────────────
    // GET /api/trips/search
    // ──────────────────────────────────────────────────────────────

    public function test_search_returns_scheduled_trips(): void
    {
        $driver  = $this->makeDriver();
        $headers = $this->headersFor($driver);
        $this->postJson('/api/driver/trips', $this->tripPayload(), $headers);

        $passenger = $this->makePassenger(['email' => 'p@test.com', 'phone' => '0790009999']);
        $pHeaders  = $this->headersFor($passenger);

        $response = $this->getJson('/api/trips/search?from=Irbid&to=Amman', $pHeaders);

        $response->assertStatus(200)
            ->assertJson(['status' => true])
            ->assertJsonCount(1, 'trips');
    }

    public function test_search_returns_empty_for_no_match(): void
    {
        $passenger = $this->makePassenger();
        $headers   = $this->headersFor($passenger);

        $response = $this->getJson('/api/trips/search?from=Aqaba&to=Irbid', $headers);

        $response->assertStatus(200)
            ->assertJsonCount(0, 'trips');
    }

    public function test_search_requires_authentication(): void
    {
        $response = $this->getJson('/api/trips/search');

        $response->assertStatus(401);
    }

    // ──────────────────────────────────────────────────────────────
    // GET /api/trips/{trip}
    // ──────────────────────────────────────────────────────────────

    public function test_show_returns_trip_with_stops(): void
    {
        $driver  = $this->makeDriver();
        $headers = $this->headersFor($driver);
        $tripId  = $this->postJson('/api/driver/trips', $this->tripPayload(), $headers)
            ->json('trip.id');

        $passenger = $this->makePassenger(['email' => 'p@test.com', 'phone' => '0790009999']);
        $pHeaders  = $this->headersFor($passenger);

        $response = $this->getJson("/api/trips/{$tripId}", $pHeaders);

        $response->assertStatus(200)
            ->assertJson(['status' => true])
            ->assertJsonPath('trip.id', $tripId)
            ->assertJsonStructure(['trip' => ['stops', 'driver']]);
    }

    public function test_show_returns_404_for_missing_trip(): void
    {
        $passenger = $this->makePassenger();
        $headers   = $this->headersFor($passenger);

        $response = $this->getJson('/api/trips/9999', $headers);

        $response->assertStatus(404);
    }

    // ──────────────────────────────────────────────────────────────
    // GET /api/driver/trips
    // ──────────────────────────────────────────────────────────────

    public function test_driver_can_list_their_trips(): void
    {
        $driver  = $this->makeDriver();
        $headers = $this->headersFor($driver);
        $this->postJson('/api/driver/trips', $this->tripPayload(), $headers);

        $response = $this->getJson('/api/driver/trips', $headers);

        $response->assertStatus(200)
            ->assertJsonCount(1, 'trips');
    }

    public function test_passenger_cannot_access_driver_trips_list(): void
    {
        $passenger = $this->makePassenger();
        $headers   = $this->headersFor($passenger);

        $response = $this->getJson('/api/driver/trips', $headers);

        $response->assertStatus(403);
    }

    // ──────────────────────────────────────────────────────────────
    // POST /api/driver/trips/{trip}/cancel
    // ──────────────────────────────────────────────────────────────

    public function test_driver_can_cancel_their_scheduled_trip(): void
    {
        $driver  = $this->makeDriver();
        $headers = $this->headersFor($driver);
        $tripId  = $this->postJson('/api/driver/trips', $this->tripPayload(), $headers)
            ->json('trip.id');

        $response = $this->postJson("/api/driver/trips/{$tripId}/cancel", [], $headers);

        $response->assertStatus(200)->assertJson(['status' => true]);
        $this->assertDatabaseHas('trips', ['id' => $tripId, 'status' => 'cancelled']);
    }

    public function test_driver_cannot_cancel_another_drivers_trip(): void
    {
        $driver1  = $this->makeDriver(['email' => 'd1@test.com', 'phone' => '0790000010']);
        $driver2  = $this->makeDriver(['email' => 'd2@test.com', 'phone' => '0790000011']);
        $h1       = $this->headersFor($driver1);
        $h2       = $this->headersFor($driver2);

        $tripId = $this->postJson('/api/driver/trips', $this->tripPayload(), $h1)
            ->json('trip.id');

        $response = $this->postJson("/api/driver/trips/{$tripId}/cancel", [], $h2);

        $response->assertStatus(403);
    }

    public function test_cannot_cancel_already_cancelled_trip(): void
    {
        $driver  = $this->makeDriver();
        $headers = $this->headersFor($driver);
        $tripId  = $this->postJson('/api/driver/trips', $this->tripPayload(), $headers)
            ->json('trip.id');

        $this->postJson("/api/driver/trips/{$tripId}/cancel", [], $headers);
        $response = $this->postJson("/api/driver/trips/{$tripId}/cancel", [], $headers);

        $response->assertStatus(400)->assertJson(['status' => false]);
    }

    // ──────────────────────────────────────────────────────────────
    // POST /api/driver/trips/{trip}/start
    // ──────────────────────────────────────────────────────────────

    public function test_driver_can_start_scheduled_trip(): void
    {
        $driver  = $this->makeDriver();
        $headers = $this->headersFor($driver);
        $tripId  = $this->postJson('/api/driver/trips', $this->tripPayload(), $headers)
            ->json('trip.id');

        $response = $this->postJson("/api/driver/trips/{$tripId}/start", [], $headers);

        $response->assertStatus(200)
            ->assertJson(['status' => true])
            ->assertJsonStructure(['checked_in_count', 'no_show_count']);

        $this->assertDatabaseHas('trips', ['id' => $tripId, 'status' => 'in_progress']);
    }

    public function test_driver_cannot_start_cancelled_trip(): void
    {
        $driver  = $this->makeDriver();
        $headers = $this->headersFor($driver);
        $tripId  = $this->postJson('/api/driver/trips', $this->tripPayload(), $headers)
            ->json('trip.id');

        $this->postJson("/api/driver/trips/{$tripId}/cancel", [], $headers);
        $response = $this->postJson("/api/driver/trips/{$tripId}/start", [], $headers);

        $response->assertStatus(400)->assertJson(['status' => false]);
    }

    // ──────────────────────────────────────────────────────────────
    // POST /api/driver/trips/{trip}/complete
    // ──────────────────────────────────────────────────────────────

    public function test_driver_can_complete_in_progress_trip(): void
    {
        $driver  = $this->makeDriver();
        $headers = $this->headersFor($driver);
        $tripId  = $this->postJson('/api/driver/trips', $this->tripPayload(), $headers)
            ->json('trip.id');

        $this->postJson("/api/driver/trips/{$tripId}/start", [], $headers);
        $response = $this->postJson("/api/driver/trips/{$tripId}/complete", [], $headers);

        $response->assertStatus(200)->assertJson(['status' => true]);
        $this->assertDatabaseHas('trips', ['id' => $tripId, 'status' => 'completed']);
    }

    // ──────────────────────────────────────────────────────────────
    // GET /api/driver/trips/history
    // ──────────────────────────────────────────────────────────────

    public function test_driver_history_returns_completed_and_cancelled_trips(): void
    {
        $driver  = $this->makeDriver();
        $headers = $this->headersFor($driver);

        // Create and complete one trip
        $tripId = $this->postJson('/api/driver/trips', $this->tripPayload(), $headers)
            ->json('trip.id');
        $this->postJson("/api/driver/trips/{$tripId}/start", [], $headers);
        $this->postJson("/api/driver/trips/{$tripId}/complete", [], $headers);

        // Create and cancel another
        $tripId2 = $this->postJson('/api/driver/trips', $this->tripPayload([
            'departure_at' => now()->addDays(2)->format('Y-m-d H:i:s'),
        ]), $headers)->json('trip.id');
        $this->postJson("/api/driver/trips/{$tripId2}/cancel", [], $headers);

        // A still-scheduled trip (should NOT appear in history)
        $this->postJson('/api/driver/trips', $this->tripPayload([
            'departure_at' => now()->addDays(3)->format('Y-m-d H:i:s'),
        ]), $headers);

        $response = $this->getJson('/api/driver/trips/history', $headers);

        $response->assertStatus(200);
        $this->assertCount(2, $response->json('trips'));
    }

    public function test_passenger_cannot_access_driver_history(): void
    {
        $passenger = $this->makePassenger();
        $headers   = $this->headersFor($passenger);

        $response = $this->getJson('/api/driver/trips/history', $headers);

        $response->assertStatus(403);
    }
}
