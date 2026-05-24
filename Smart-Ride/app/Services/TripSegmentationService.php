<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Trip;
use App\Models\TripSegment;
use App\Models\TripStop;
use App\Models\User;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;
use RuntimeException;

/**
 * Ride Segmentation / Multi-Stop Booking — business logic.
 *
 * Encapsulates the seven required operations:
 *   - createTrip(), addStop(), generateSegments(), searchAvailableTrips(),
 *     bookSegment(), cancelBooking(), calculateSegmentPrice()
 *
 * The corresponding HTTP layer is in App\Http\Controllers\Api\SegmentController.
 */
class TripSegmentationService
{
    // ---------------------------------------------------------------
    // createTrip
    // ---------------------------------------------------------------

    /**
     * Create a trip and immediately seed its origin/destination stops.
     * Caller can then addStop() for any intermediate cities before
     * generateSegments() is called.
     *
     * @param  array<string,mixed>  $data
     */
    public function createTrip(User $driver, array $data): Trip
    {
        if ($driver->role !== 'driver') {
            throw new InvalidArgumentException('Only drivers can create trips.');
        }
        $this->requireFields($data, [
            'origin', 'destination', 'departure_at',
            'seats_total', 'price_per_seat',
        ]);
        if ($data['origin'] === $data['destination']) {
            throw new InvalidArgumentException('Origin and destination must differ.');
        }
        if ((int) $data['seats_total'] <= 0) {
            throw new InvalidArgumentException('seats_total must be positive.');
        }

        return DB::transaction(function () use ($driver, $data) {
            $trip = Trip::create([
                'driver_id'       => $driver->id,
                'origin'          => $data['origin'],
                'destination'     => $data['destination'],
                'departure_at'    => Carbon::parse($data['departure_at']),
                'seats_total'     => (int) $data['seats_total'],
                'seats_available' => (int) $data['seats_total'],
                'min_passengers'  => (int) ($data['min_passengers'] ?? 1),
                'price_per_seat'  => (float) $data['price_per_seat'],
                'car_model'       => $data['car_model']  ?? null,
                'car_plate'       => $data['car_plate']  ?? null,
                'notes'           => $data['notes']      ?? null,
                'status'          => 'scheduled',
            ]);

            // Always include origin and destination as ordered stops.
            TripStop::create([
                'trip_id'     => $trip->id,
                'name'        => $trip->origin,
                'order_index' => 0,
            ]);
            TripStop::create([
                'trip_id'     => $trip->id,
                'name'        => $trip->destination,
                'order_index' => 1,
            ]);

            return $trip->fresh('stops');
        });
    }

    // ---------------------------------------------------------------
    // addStop
    // ---------------------------------------------------------------

    /**
     * Insert an intermediate stop into a trip. The new stop is
     * appended just before the destination.
     */
    public function addStop(Trip $trip, string $stopName): TripStop
    {
        $stopName = trim($stopName);
        if ($stopName === '') {
            throw new InvalidArgumentException('Stop name is required.');
        }
        if ($stopName === $trip->origin || $stopName === $trip->destination) {
            throw new InvalidArgumentException(
                'Stop cannot equal origin or destination.'
            );
        }

        // Disallow duplicates.
        if ($trip->stops()->where('name', $stopName)->exists()) {
            throw new InvalidArgumentException("Stop {$stopName} already exists.");
        }

        return DB::transaction(function () use ($trip, $stopName) {
            $destStop = $trip->stops()->where('name', $trip->destination)->first();

            // Push destination one slot down so the new stop comes before it.
            if ($destStop) {
                $destStop->order_index = $destStop->order_index + 1;
                $destStop->save();
            }

            return TripStop::create([
                'trip_id'     => $trip->id,
                'name'        => $stopName,
                'order_index' => $destStop ? $destStop->order_index - 1
                                           : $trip->stops()->count(),
            ]);
        });
    }

    // ---------------------------------------------------------------
    // generateSegments
    // ---------------------------------------------------------------

    /**
     * Build (or rebuild) the trip_segments rows from the trip's ordered
     * stops. Safe to call multiple times before any bookings exist.
     *
     * @param  Trip               $trip
     * @param  array<int, float>  $segmentPrices  Optional. Ordered prices
     *         per segment. If provided, the i-th price is applied to the
     *         i-th leg (e.g. [3.0, 2.0] for Irbid→Jarash=3, Jarash→Amman=2).
     *         Must have exactly (stops - 1) elements if supplied.
     *         Falls back to price_per_seat when omitted or wrong length.
     * @return Collection<int, TripSegment>
     */
    public function generateSegments(Trip $trip, array $segmentPrices = []): Collection
    {
        return DB::transaction(function () use ($trip, $segmentPrices) {
            // Refuse to regenerate if there are already active bookings,
            // since that would invalidate seat math.
            $hasActive = $trip->bookings()
                ->whereIn('status', ['pending', 'accepted'])
                ->exists();
            if ($hasActive && $trip->segments()->exists()) {
                throw new RuntimeException(
                    'Cannot regenerate segments: active bookings exist.'
                );
            }

            $points = $trip->orderedPoints();
            if (count($points) < 2) {
                throw new RuntimeException(
                    'Trip needs at least origin and destination.'
                );
            }

            // Wipe and rebuild.
            $trip->segments()->delete();

            $count = count($points) - 1;
            $totalMinutes = $this->estimateTotalMinutes($trip);
            $segmentMinutes = max(1, intdiv($totalMinutes, $count));

            // Validate provided prices array length.
            $usePrices = (count($segmentPrices) === $count);

            for ($i = 0; $i < $count; $i++) {
                // Use the driver-supplied price when available and valid (>= 0).
                $price = ($usePrices && isset($segmentPrices[$i]) && (float)$segmentPrices[$i] >= 0)
                    ? (float) $segmentPrices[$i]
                    : $this->calculateSegmentPrice($trip);

                TripSegment::create([
                    'trip_id'           => $trip->id,
                    'order_index'       => $i,
                    'start_stop'        => $points[$i],
                    'end_stop'          => $points[$i + 1],
                    'seats_total'       => $trip->seats_total,
                    'seats_available'   => $trip->seats_total,
                    'price'             => $price,
                    'estimated_minutes' => $segmentMinutes,
                ]);
            }

            return $trip->segments()->get();
        });
    }

    // ---------------------------------------------------------------
    // calculateSegmentPrice
    // ---------------------------------------------------------------

    /**
     * Simple, beginner-friendly model: every leg costs the trip's
     * `price_per_seat` for one seat. This is also where you could plug
     * in distance-based pricing later.
     */
    public function calculateSegmentPrice(Trip $trip): float
    {
        return (float) $trip->price_per_seat;
    }

    // ---------------------------------------------------------------
    // searchAvailableTrips
    // ---------------------------------------------------------------

    /**
     * Find every scheduled trip whose ordered stop list contains
     * `$from` followed (later) by `$to`, with enough seats free on
     * every segment in between.
     *
     * @return Collection<int, Trip>
     */
    public function searchAvailableTrips(string $from, string $to, int $seats = 1): Collection
    {
        if ($from === '' || $to === '' || $from === $to) {
            return new Collection();
        }
        if ($seats <= 0) {
            return new Collection();
        }

        $trips = Trip::with(['driver:id,name,phone,city,image', 'segments'])
            ->where('status', 'scheduled')
            ->where('departure_at', '>=', now())
            ->get();

        return $trips->filter(function (Trip $trip) use ($from, $to, $seats) {
            $route = $this->segmentsBetween($trip, $from, $to);
            if ($route->isEmpty()) return false;
            foreach ($route as $seg) {
                if (!$seg->hasAvailableSeats($seats)) return false;
            }
            return true;
        })->values();
    }

    // ---------------------------------------------------------------
    // bookSegment
    // ---------------------------------------------------------------

    /**
     * Book a sub-route `$from -> $to` on `$trip` for `$passenger`.
     * Validates the route, ensures every overlapping segment has
     * room, blocks duplicate active bookings, and reserves the seats
     * inside a single DB transaction.
     */
    public function bookSegment(
        User $passenger,
        Trip $trip,
        string $from,
        string $to,
        int $seats,
        ?string $locationArea     = null,
        ?string $locationStreet   = null,
        ?string $locationBuilding = null
    ): Booking {
        if ($passenger->role !== 'passenger') {
            throw new InvalidArgumentException('Only passengers can book.');
        }
        if ($seats <= 0) {
            throw new InvalidArgumentException('Seats must be positive.');
        }

        return DB::transaction(function () use ($passenger, $trip, $from, $to, $seats, $locationArea, $locationStreet, $locationBuilding) {

            // Lock the relevant segments to prevent over-booking races.
            $route = TripSegment::where('trip_id', $trip->id)
                ->orderBy('order_index')
                ->lockForUpdate()
                ->get();

            $startIdx = $route->search(fn ($s) => $s->start_stop === $from);
            $endIdx   = $route->search(fn ($s) => $s->end_stop === $to);

            if ($startIdx === false || $endIdx === false || $startIdx > $endIdx) {
                throw new InvalidArgumentException(
                    "Invalid route: {$from} -> {$to} is not part of trip #{$trip->id}."
                );
            }

            $sub = $route->slice($startIdx, $endIdx - $startIdx + 1)->values();

            // Duplicate guard.
            $duplicate = Booking::where('trip_id', $trip->id)
                ->where('passenger_id', $passenger->id)
                ->where('pickup_stop', $from)
                ->where('dropoff_stop', $to)
                ->whereIn('status', ['pending', 'accepted'])
                ->exists();
            if ($duplicate) {
                throw new InvalidArgumentException(
                    'You already have an active booking for this route.'
                );
            }

            // Capacity check on every overlapping leg.
            // Note: seats are NOT reserved yet — they are only reserved when
            // the driver accepts the booking. This keeps the trip visible to
            // all passengers while their requests are pending.
            foreach ($sub as $seg) {
                if (!$seg->hasAvailableSeats($seats)) {
                    throw new RuntimeException(
                        "Not enough seats on segment {$seg->start_stop} -> {$seg->end_stop}."
                    );
                }
            }

            $tripPrice = round($sub->sum(fn ($s) => (float) $s->price) * $seats, 2);

            // ── No-show debt: roll outstanding balance into this booking ──
            $debtCarried     = 0.00;
            $passengerBalance = (float) $passenger->balance;
            if ($passengerBalance < 0) {
                $debtCarried = round(abs($passengerBalance), 2);
                $tripPrice   = round($tripPrice + $debtCarried, 2);
            }

            $booking = Booking::create([
                'trip_id'          => $trip->id,
                'passenger_id'     => $passenger->id,
                'pickup_stop'      => $from,
                'dropoff_stop'     => $to,
                'seats'            => $seats,
                'total_price'      => $tripPrice,
                'debt_carried'     => $debtCarried,
                'status'           => 'pending',
                'location_area'     => $locationArea,
                'location_street'   => $locationStreet,
                'location_building' => $locationBuilding,
            ]);

            // Pivot rows so we know exactly which legs the booking holds.
            $pivot = [];
            foreach ($sub as $seg) {
                $pivot[$seg->id] = ['seats' => $seats];
            }
            $booking->segments()->sync($pivot);

            return $booking->load('segments');
        });
    }

    // ---------------------------------------------------------------
    // cancelBooking
    // ---------------------------------------------------------------

    /**
     * Release the seats this booking occupies and mark it cancelled.
     */
    public function cancelBooking(Booking $booking): Booking
    {
        if (in_array($booking->status, ['cancelled', 'completed', 'rejected'], true)) {
            throw new InvalidArgumentException(
                "Booking is already {$booking->status}."
            );
        }

        // Cannot cancel after the passenger has already checked in
        if ($booking->is_checked_in) {
            throw new InvalidArgumentException(
                'You cannot cancel a booking after you have already checked in.'
            );
        }

        return DB::transaction(function () use ($booking) {
            // Only release seats if the booking was accepted — seats are
            // reserved at acceptance time, not at booking creation.
            if ($booking->status === 'accepted') {
                $segments = $booking->segments()->lockForUpdate()->get();
                foreach ($segments as $seg) {
                    /** @var int $seats */
                    $seats = (int) $seg->pivot->seats;
                    $seg->releaseSeats($seats);
                }

                // Re-sync the trip-level display counter.
                $minAvail = TripSegment::where('trip_id', $booking->trip_id)->min('seats_available');
                if ($minAvail !== null) {
                    $booking->trip()->update(['seats_available' => $minAvail]);
                }

                // ── Debt re-application on cancellation ───────────────────
                // Debt was cleared from balance when accepted; put it back
                // now that the passenger is no longer paying via this booking.
                if ((float) $booking->debt_carried > 0) {
                    $booking->passenger()->first()->decrement('balance', (float) $booking->debt_carried);
                }
            }

            $booking->status = 'cancelled';
            $booking->save();
            return $booking->fresh('segments');
        });
    }

    // ---------------------------------------------------------------
    // Internal helpers
    // ---------------------------------------------------------------

    /**
     * Returns the contiguous list of TripSegments needed to travel
     * `$from -> $to` on `$trip`. Empty when the route is invalid.
     *
     * @return Collection<int, TripSegment>
     */
    public function segmentsBetween(Trip $trip, string $from, string $to): Collection
    {
        $segs = $trip->segments()->orderBy('order_index')->get();
        $startIdx = $segs->search(fn ($s) => $s->start_stop === $from);
        $endIdx   = $segs->search(fn ($s) => $s->end_stop === $to);
        if ($startIdx === false || $endIdx === false || $startIdx > $endIdx) {
            return new Collection();
        }
        return $segs->slice($startIdx, $endIdx - $startIdx + 1)->values();
    }

    private function estimateTotalMinutes(Trip $trip): int
    {
        // No total time column today; use a sensible default of 60 min
        // per leg unless notes contain a hint. Drivers can edit later.
        $points = $trip->orderedPoints();
        $legs = max(1, count($points) - 1);
        return 60 * $legs;
    }

    /**
     * @param  array<string,mixed>  $data
     * @param  array<int,string>    $required
     */
    private function requireFields(array $data, array $required): void
    {
        foreach ($required as $field) {
            if (!array_key_exists($field, $data) || $data[$field] === null
                || $data[$field] === '') {
                throw new InvalidArgumentException("Missing field: {$field}");
            }
        }
    }
}
