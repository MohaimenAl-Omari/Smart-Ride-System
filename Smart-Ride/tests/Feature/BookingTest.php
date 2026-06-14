<?php

namespace Tests\Feature;

use App\Models\Booking;
use App\Models\Trip;
use App\Models\User;
use Tests\TestCase;

class BookingTest extends TestCase
{
    // ── Helpers ───────────────────────────────────────────────────

    /**
     * Create a driver, post a trip, return [driver, headers, tripId].
     */
    private function createScheduledTrip(array $tripOverrides = []): array
    {
        $driver  = $this->makeDriver();
        $headers = $this->headersFor($driver);

        $tripId = $this->postJson('/api/driver/trips', $this->tripPayload($tripOverrides), $headers)
            ->json('trip.id');

        return [$driver, $headers, $tripId];
    }

    /**
     * Create a passenger, post a booking for $tripId, return [passenger, headers, bookingId].
     */
    private function createBooking(int $tripId, array $overrides = []): array
    {
        $passenger = $this->makePassenger([
            'email' => $overrides['email'] ?? 'passenger@test.com',
            'phone' => $overrides['phone'] ?? '0790099999',
        ]);
        $headers = $this->headersFor($passenger);

        $payload = array_merge([
            'trip_id' => $tripId,
            'seats'   => 1,
        ], $overrides);
        unset($payload['email'], $payload['phone']);

        $bookingId = $this->postJson('/api/bookings', $payload, $headers)
            ->json('booking.id');

        return [$passenger, $headers, $bookingId];
    }

    // ──────────────────────────────────────────────────────────────
    // POST /api/bookings
    // ──────────────────────────────────────────────────────────────

    public function test_passenger_can_create_booking(): void
    {
        [, , $tripId] = $this->createScheduledTrip();
        [$passenger, $headers] = $this->createBooking($tripId);

        $this->assertDatabaseHas('bookings', [
            'trip_id'      => $tripId,
            'passenger_id' => $passenger->id,
            'status'       => 'pending',
        ]);
    }

    public function test_booking_response_contains_booking_object(): void
    {
        [, , $tripId] = $this->createScheduledTrip();
        [, $headers] = $this->createBooking($tripId);

        // Re-book would fail; just verify the first booking returned 200
        $passenger2 = $this->makePassenger(['email' => 'p2@test.com', 'phone' => '0790000020']);
        $h2         = $this->headersFor($passenger2);

        $response = $this->postJson('/api/bookings', ['trip_id' => $tripId, 'seats' => 1], $h2);

        $response->assertStatus(200)
            ->assertJson(['status' => true])
            ->assertJsonStructure(['booking' => ['id', 'status', 'trip']]);
    }

    public function test_driver_cannot_book_their_own_trip(): void
    {
        [$driver, $driverHeaders, $tripId] = $this->createScheduledTrip();

        $response = $this->postJson('/api/bookings', [
            'trip_id' => $tripId,
            'seats'   => 1,
        ], $driverHeaders);

        $response->assertStatus(403);
    }

    public function test_passenger_cannot_double_book_same_trip(): void
    {
        [, , $tripId] = $this->createScheduledTrip();
        [, $headers]  = $this->createBooking($tripId);

        $response = $this->postJson('/api/bookings', [
            'trip_id' => $tripId,
            'seats'   => 1,
        ], $headers);

        $response->assertStatus(400)
            ->assertJson(['status' => false]);
    }

    public function test_booking_fails_when_not_enough_seats(): void
    {
        [, , $tripId] = $this->createScheduledTrip(['seats_total' => 1]);
        [, $headers]  = $this->createBooking($tripId);

        // Accept the first booking to consume the seat
        [, $driverH] = array_slice($this->createScheduledTrip(), 0, 2);
        // (using a fresh trip is simpler to avoid cross-driver issues)
        [, , $tripId2] = $this->createScheduledTrip([
            'seats_total'  => 1,
            'departure_at' => now()->addDays(2)->format('Y-m-d H:i:s'),
        ]);

        $p1 = $this->makePassenger(['email' => 'p1@test.com', 'phone' => '0790000031']);
        $p2 = $this->makePassenger(['email' => 'p2@test.com', 'phone' => '0790000032']);
        $h1 = $this->headersFor($p1);
        $h2 = $this->headersFor($p2);

        // First passenger books and driver accepts
        $bookingId = $this->postJson('/api/bookings', ['trip_id' => $tripId2, 'seats' => 1], $h1)
            ->json('booking.id');

        $trip2   = Trip::find($tripId2);
        $driver2 = User::find($trip2->driver_id);
        $dh2     = $this->headersFor($driver2);

        $this->postJson("/api/driver/bookings/{$bookingId}/accept", [], $dh2);

        // Second passenger tries to book — no seats left
        $response = $this->postJson('/api/bookings', ['trip_id' => $tripId2, 'seats' => 1], $h2);

        $response->assertStatus(400)->assertJson(['status' => false]);
    }

    public function test_booking_fails_when_trip_is_not_scheduled(): void
    {
        [$driver, $driverHeaders, $tripId] = $this->createScheduledTrip();
        $this->postJson("/api/driver/trips/{$tripId}/cancel", [], $driverHeaders);

        $passenger = $this->makePassenger(['email' => 'p@test.com', 'phone' => '0790000041']);
        $headers   = $this->headersFor($passenger);

        $response = $this->postJson('/api/bookings', ['trip_id' => $tripId, 'seats' => 1], $headers);

        $response->assertStatus(400)->assertJson(['status' => false]);
    }

    public function test_booking_requires_authentication(): void
    {
        [, , $tripId] = $this->createScheduledTrip();

        $response = $this->postJson('/api/bookings', ['trip_id' => $tripId, 'seats' => 1]);

        $response->assertStatus(401);
    }

    // ──────────────────────────────────────────────────────────────
    // GET /api/bookings/mine
    // ──────────────────────────────────────────────────────────────

    public function test_passenger_can_see_their_bookings(): void
    {
        [, , $tripId] = $this->createScheduledTrip();
        [, $headers]  = $this->createBooking($tripId);

        $response = $this->getJson('/api/bookings/mine', $headers);

        $response->assertStatus(200)
            ->assertJsonCount(1, 'bookings');
    }

    public function test_passenger_does_not_see_other_passengers_bookings(): void
    {
        [, , $tripId] = $this->createScheduledTrip();
        $this->createBooking($tripId);

        $other = $this->makePassenger(['email' => 'other@test.com', 'phone' => '0790000051']);
        $oH    = $this->headersFor($other);

        $response = $this->getJson('/api/bookings/mine', $oH);

        $response->assertStatus(200)->assertJsonCount(0, 'bookings');
    }

    // ──────────────────────────────────────────────────────────────
    // GET /api/driver/bookings
    // ──────────────────────────────────────────────────────────────

    public function test_driver_can_see_bookings_for_their_trips(): void
    {
        [$driver, $driverHeaders, $tripId] = $this->createScheduledTrip();
        $this->createBooking($tripId);

        $response = $this->getJson('/api/driver/bookings', $driverHeaders);

        $response->assertStatus(200)
            ->assertJsonCount(1, 'bookings');
    }

    // ──────────────────────────────────────────────────────────────
    // POST /api/driver/bookings/{booking}/accept
    // ──────────────────────────────────────────────────────────────

    public function test_driver_can_accept_pending_booking(): void
    {
        [$driver, $driverHeaders, $tripId] = $this->createScheduledTrip();
        [, , $bookingId]                   = $this->createBooking($tripId);

        $response = $this->postJson("/api/driver/bookings/{$bookingId}/accept", [], $driverHeaders);

        $response->assertStatus(200)->assertJson(['status' => true]);
        $this->assertDatabaseHas('bookings', ['id' => $bookingId, 'status' => 'accepted']);
    }

    public function test_accepting_booking_decrements_available_seats(): void
    {
        [$driver, $driverHeaders, $tripId] = $this->createScheduledTrip(['seats_total' => 3]);
        [, , $bookingId]                   = $this->createBooking($tripId);

        $this->postJson("/api/driver/bookings/{$bookingId}/accept", [], $driverHeaders);

        $trip = Trip::find($tripId);
        $this->assertEquals(2, $trip->seats_available);
    }

    public function test_driver_cannot_accept_already_accepted_booking(): void
    {
        [$driver, $driverHeaders, $tripId] = $this->createScheduledTrip();
        [, , $bookingId]                   = $this->createBooking($tripId);

        $this->postJson("/api/driver/bookings/{$bookingId}/accept", [], $driverHeaders);
        $response = $this->postJson("/api/driver/bookings/{$bookingId}/accept", [], $driverHeaders);

        $response->assertStatus(400)->assertJson(['status' => false]);
    }

    public function test_wrong_driver_cannot_accept_booking(): void
    {
        [, , $tripId] = $this->createScheduledTrip();
        [, , $bookingId] = $this->createBooking($tripId);

        $otherDriver = $this->makeDriver(['email' => 'other@driver.com', 'phone' => '0790000060']);
        $oH          = $this->headersFor($otherDriver);

        $response = $this->postJson("/api/driver/bookings/{$bookingId}/accept", [], $oH);

        $response->assertStatus(403);
    }

    // ──────────────────────────────────────────────────────────────
    // POST /api/driver/bookings/{booking}/reject
    // ──────────────────────────────────────────────────────────────

    public function test_driver_can_reject_pending_booking(): void
    {
        [$driver, $driverHeaders, $tripId] = $this->createScheduledTrip();
        [, , $bookingId]                   = $this->createBooking($tripId);

        $response = $this->postJson("/api/driver/bookings/{$bookingId}/reject", [], $driverHeaders);

        $response->assertStatus(200)->assertJson(['status' => true]);
        $this->assertDatabaseHas('bookings', ['id' => $bookingId, 'status' => 'rejected']);
    }

    public function test_driver_cannot_reject_non_pending_booking(): void
    {
        [$driver, $driverHeaders, $tripId] = $this->createScheduledTrip();
        [, , $bookingId]                   = $this->createBooking($tripId);

        $this->postJson("/api/driver/bookings/{$bookingId}/accept", [], $driverHeaders);
        $response = $this->postJson("/api/driver/bookings/{$bookingId}/reject", [], $driverHeaders);

        $response->assertStatus(400)->assertJson(['status' => false]);
    }

    // ──────────────────────────────────────────────────────────────
    // POST /api/bookings/{booking}/cancel
    // ──────────────────────────────────────────────────────────────

    public function test_passenger_can_cancel_pending_booking(): void
    {
        [, , $tripId]          = $this->createScheduledTrip();
        [, $pHeaders, $bookingId] = $this->createBooking($tripId);

        $response = $this->postJson("/api/bookings/{$bookingId}/cancel", [], $pHeaders);

        $response->assertStatus(200)->assertJson(['status' => true]);
        $this->assertDatabaseHas('bookings', ['id' => $bookingId, 'status' => 'cancelled']);
    }

    public function test_passenger_can_cancel_accepted_booking(): void
    {
        [$driver, $driverHeaders, $tripId] = $this->createScheduledTrip();
        [$passenger, $pHeaders, $bookingId] = $this->createBooking($tripId);

        $this->postJson("/api/driver/bookings/{$bookingId}/accept", [], $driverHeaders);
        $response = $this->postJson("/api/bookings/{$bookingId}/cancel", [], $pHeaders);

        $response->assertStatus(200)->assertJson(['status' => true]);
        $this->assertDatabaseHas('bookings', ['id' => $bookingId, 'status' => 'cancelled']);
    }

    public function test_cancelling_accepted_booking_restores_seats(): void
    {
        [$driver, $driverHeaders, $tripId] = $this->createScheduledTrip(['seats_total' => 3]);
        [, $pHeaders, $bookingId]          = $this->createBooking($tripId);

        $this->postJson("/api/driver/bookings/{$bookingId}/accept", [], $driverHeaders);
        $this->postJson("/api/bookings/{$bookingId}/cancel", [], $pHeaders);

        $trip = Trip::find($tripId);
        $this->assertEquals(3, $trip->seats_available);
    }

    public function test_other_passenger_cannot_cancel_booking(): void
    {
        [, , $tripId]          = $this->createScheduledTrip();
        [, , $bookingId]       = $this->createBooking($tripId);

        $other = $this->makePassenger(['email' => 'other@test.com', 'phone' => '0790000070']);
        $oH    = $this->headersFor($other);

        $response = $this->postJson("/api/bookings/{$bookingId}/cancel", [], $oH);

        $response->assertStatus(403);
    }

    // ──────────────────────────────────────────────────────────────
    // POST /api/bookings/{booking}/checkin
    // ──────────────────────────────────────────────────────────────

    public function test_passenger_can_check_in_within_window(): void
    {
        [$driver, $driverHeaders, $tripId] = $this->createScheduledTrip([
            'departure_at' => now()->addMinutes(30)->format('Y-m-d H:i:s'),
        ]);
        [$passenger, $pHeaders, $bookingId] = $this->createBooking($tripId);
        $this->postJson("/api/driver/bookings/{$bookingId}/accept", [], $driverHeaders);

        $response = $this->postJson("/api/bookings/{$bookingId}/checkin", [], $pHeaders);

        $response->assertStatus(200)->assertJson(['status' => true]);
        $this->assertDatabaseHas('bookings', ['id' => $bookingId, 'is_checked_in' => 1]);
    }

    public function test_check_in_fails_too_early(): void
    {
        [$driver, $driverHeaders, $tripId] = $this->createScheduledTrip([
            'departure_at' => now()->addHours(3)->format('Y-m-d H:i:s'),
        ]);
        [$passenger, $pHeaders, $bookingId] = $this->createBooking($tripId);
        $this->postJson("/api/driver/bookings/{$bookingId}/accept", [], $driverHeaders);

        $response = $this->postJson("/api/bookings/{$bookingId}/checkin", [], $pHeaders);

        $response->assertStatus(400)->assertJson(['status' => false]);
    }

    public function test_check_in_fails_for_non_accepted_booking(): void
    {
        [, , $tripId]            = $this->createScheduledTrip([
            'departure_at' => now()->addMinutes(30)->format('Y-m-d H:i:s'),
        ]);
        [, $pHeaders, $bookingId] = $this->createBooking($tripId);

        $response = $this->postJson("/api/bookings/{$bookingId}/checkin", [], $pHeaders);

        $response->assertStatus(400)->assertJson(['status' => false]);
    }

    public function test_passenger_cannot_check_in_twice(): void
    {
        [$driver, $driverHeaders, $tripId] = $this->createScheduledTrip([
            'departure_at' => now()->addMinutes(30)->format('Y-m-d H:i:s'),
        ]);
        [, $pHeaders, $bookingId] = $this->createBooking($tripId);
        $this->postJson("/api/driver/bookings/{$bookingId}/accept", [], $driverHeaders);
        $this->postJson("/api/bookings/{$bookingId}/checkin", [], $pHeaders);

        $response = $this->postJson("/api/bookings/{$bookingId}/checkin", [], $pHeaders);

        $response->assertStatus(400)->assertJson(['status' => false]);
    }

    // ──────────────────────────────────────────────────────────────
    // POST /api/driver/bookings/{booking}/checkin
    // ──────────────────────────────────────────────────────────────

    public function test_driver_can_check_in_passenger(): void
    {
        [$driver, $driverHeaders, $tripId] = $this->createScheduledTrip();
        [, , $bookingId]                   = $this->createBooking($tripId);
        $this->postJson("/api/driver/bookings/{$bookingId}/accept", [], $driverHeaders);

        $response = $this->postJson("/api/driver/bookings/{$bookingId}/checkin", [], $driverHeaders);

        $response->assertStatus(200)->assertJson(['status' => true]);
        $this->assertDatabaseHas('bookings', ['id' => $bookingId, 'is_checked_in' => 1]);
    }

    // ──────────────────────────────────────────────────────────────
    // POST /api/bookings/{booking}/payment-method
    // ──────────────────────────────────────────────────────────────

    public function test_passenger_can_set_payment_method(): void
    {
        [, , $tripId]              = $this->createScheduledTrip();
        [, $pHeaders, $bookingId]  = $this->createBooking($tripId);

        $response = $this->postJson(
            "/api/bookings/{$bookingId}/payment-method",
            ['payment_method' => 'cash'],
            $pHeaders
        );

        $response->assertStatus(200)->assertJson(['status' => true]);
        $this->assertDatabaseHas('bookings', ['id' => $bookingId, 'payment_method' => 'cash']);
    }

    public function test_invalid_payment_method_is_rejected(): void
    {
        [, , $tripId]              = $this->createScheduledTrip();
        [, $pHeaders, $bookingId]  = $this->createBooking($tripId);

        $response = $this->postJson(
            "/api/bookings/{$bookingId}/payment-method",
            ['payment_method' => 'bitcoin'],
            $pHeaders
        );

        $response->assertStatus(400)->assertJson(['status' => false]);
    }

    // ──────────────────────────────────────────────────────────────
    // No-show penalty on trip start
    // ──────────────────────────────────────────────────────────────

    public function test_no_show_passenger_balance_is_decremented(): void
    {
        [$driver, $driverHeaders, $tripId] = $this->createScheduledTrip();
        [$passenger, $pHeaders, $bookingId] = $this->createBooking($tripId);

        $this->postJson("/api/driver/bookings/{$bookingId}/accept", [], $driverHeaders);
        // Passenger does NOT check in → no-show when trip starts
        $this->postJson("/api/driver/trips/{$tripId}/start", [], $driverHeaders);

        $passenger->refresh();
        $price = Booking::find($bookingId)->total_price;
        $this->assertEquals(0 - (float) $price, (float) $passenger->balance);
    }
}
