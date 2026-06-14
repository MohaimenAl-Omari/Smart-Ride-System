<?php

namespace Tests\Feature;

use App\Models\Booking;
use App\Models\Trip;
use App\Models\TripRating;
use Tests\TestCase;

class RatingTest extends TestCase
{
    // ── Helpers ───────────────────────────────────────────────────

    /**
     * Sets up a completed booking ready to be rated.
     * Returns [$passenger, $passengerHeaders, $driver, $booking].
     */
    private function completedBookingSetup(): array
    {
        $driver    = $this->makeDriver();
        $driverH   = $this->headersFor($driver);

        $tripId = $this->postJson('/api/driver/trips', $this->tripPayload([
            'departure_at' => now()->addMinutes(25)->format('Y-m-d H:i:s'),
        ]), $driverH)->json('trip.id');

        $passenger = $this->makePassenger(['email' => 'p@test.com', 'phone' => '0790099999']);
        $pH        = $this->headersFor($passenger);

        $bookingId = $this->postJson('/api/bookings', ['trip_id' => $tripId, 'seats' => 1], $pH)
            ->json('booking.id');

        $this->postJson("/api/driver/bookings/{$bookingId}/accept", [], $driverH);
        $this->postJson("/api/bookings/{$bookingId}/checkin", [], $pH);
        $this->postJson("/api/driver/trips/{$tripId}/start", [], $driverH);
        $this->postJson("/api/driver/trips/{$tripId}/complete", [], $driverH);

        $booking = Booking::find($bookingId);

        return [$passenger, $pH, $driver, $booking];
    }

    // ──────────────────────────────────────────────────────────────
    // POST /api/ratings
    // ──────────────────────────────────────────────────────────────

    public function test_passenger_can_rate_completed_booking(): void
    {
        [$passenger, $pH, $driver, $booking] = $this->completedBookingSetup();

        $response = $this->postJson('/api/ratings', [
            'booking_id' => $booking->id,
            'stars'      => 5,
            'review'     => 'Excellent driver!',
        ], $pH);

        $response->assertStatus(200)
            ->assertJson(['status' => true])
            ->assertJsonStructure(['rating', 'driver' => ['rating_average', 'ratings_count']]);

        $this->assertDatabaseHas('trip_ratings', [
            'booking_id'   => $booking->id,
            'passenger_id' => $passenger->id,
            'driver_id'    => $driver->id,
            'stars'        => 5,
        ]);
    }

    public function test_rating_fails_with_invalid_stars(): void
    {
        [, $pH, , $booking] = $this->completedBookingSetup();

        $response = $this->postJson('/api/ratings', [
            'booking_id' => $booking->id,
            'stars'      => 6,
        ], $pH);

        $response->assertStatus(400)->assertJson(['status' => false]);
    }

    public function test_passenger_cannot_rate_twice(): void
    {
        [, $pH, , $booking] = $this->completedBookingSetup();

        $this->postJson('/api/ratings', ['booking_id' => $booking->id, 'stars' => 4], $pH);
        $response = $this->postJson('/api/ratings', ['booking_id' => $booking->id, 'stars' => 3], $pH);

        $response->assertStatus(400)->assertJson(['status' => false]);
    }

    public function test_driver_cannot_submit_rating(): void
    {
        [, , $driver, $booking] = $this->completedBookingSetup();
        $dH = $this->headersFor($driver);

        $response = $this->postJson('/api/ratings', [
            'booking_id' => $booking->id,
            'stars'      => 5,
        ], $dH);

        $response->assertStatus(403)->assertJson(['status' => false]);
    }

    public function test_cannot_rate_non_completed_booking(): void
    {
        $driver    = $this->makeDriver();
        $driverH   = $this->headersFor($driver);
        $tripId    = $this->postJson('/api/driver/trips', $this->tripPayload(), $driverH)
            ->json('trip.id');

        $passenger = $this->makePassenger(['email' => 'p@test.com', 'phone' => '0790099999']);
        $pH        = $this->headersFor($passenger);

        $bookingId = $this->postJson('/api/bookings', ['trip_id' => $tripId, 'seats' => 1], $pH)
            ->json('booking.id');
        // Booking is still pending — not completed
        $response = $this->postJson('/api/ratings', ['booking_id' => $bookingId, 'stars' => 3], $pH);

        $response->assertStatus(400)->assertJson(['status' => false]);
    }

    public function test_rating_requires_authentication(): void
    {
        $response = $this->postJson('/api/ratings', ['booking_id' => 1, 'stars' => 5]);

        $response->assertStatus(401);
    }

    // ──────────────────────────────────────────────────────────────
    // GET /api/drivers/{driver}/ratings
    // ──────────────────────────────────────────────────────────────

    public function test_anyone_authenticated_can_view_driver_ratings(): void
    {
        [$passenger, $pH, $driver, $booking] = $this->completedBookingSetup();

        $this->postJson('/api/ratings', ['booking_id' => $booking->id, 'stars' => 4], $pH);

        $viewer  = $this->makePassenger(['email' => 'viewer@test.com', 'phone' => '0790000080']);
        $viewerH = $this->headersFor($viewer);

        $response = $this->getJson("/api/drivers/{$driver->id}/ratings", $viewerH);

        $response->assertStatus(200)
            ->assertJson(['status' => true])
            ->assertJsonStructure(['rating_average', 'ratings_count', 'ratings'])
            ->assertJsonCount(1, 'ratings');
    }

    public function test_driver_ratings_returns_empty_when_no_ratings(): void
    {
        $driver    = $this->makeDriver();
        $passenger = $this->makePassenger(['email' => 'p@test.com', 'phone' => '0790099999']);
        $pH        = $this->headersFor($passenger);

        $response = $this->getJson("/api/drivers/{$driver->id}/ratings", $pH);

        $response->assertStatus(200)
            ->assertJsonPath('ratings_count', 0)
            ->assertJsonCount(0, 'ratings');
    }

    public function test_ratings_endpoint_rejects_non_driver_user(): void
    {
        $passenger  = $this->makePassenger(['email' => 'p@test.com', 'phone' => '0790099999']);
        $passenger2 = $this->makePassenger(['email' => 'p2@test.com', 'phone' => '0790099998']);
        $pH         = $this->headersFor($passenger2);

        $response = $this->getJson("/api/drivers/{$passenger->id}/ratings", $pH);

        $response->assertStatus(400)->assertJson(['status' => false]);
    }

    public function test_ratings_endpoint_requires_authentication(): void
    {
        $driver   = $this->makeDriver();
        $response = $this->getJson("/api/drivers/{$driver->id}/ratings");

        $response->assertStatus(401);
    }

    public function test_driver_average_rating_is_calculated_correctly(): void
    {
        [$passenger, $pH, $driver, $booking] = $this->completedBookingSetup();

        $this->postJson('/api/ratings', ['booking_id' => $booking->id, 'stars' => 4], $pH);

        $driver->refresh();
        $this->assertEquals(4.0, $driver->rating_average);
        $this->assertEquals(1, $driver->ratings_count);
    }
}
