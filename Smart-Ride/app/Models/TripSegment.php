<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

/**
 * A single leg of a multi-stop trip (e.g. Irbid → Amman).
 *
 * Encapsulates per-segment seat tracking, price and estimated time so
 * passengers can book overlapping portions of the same physical ride
 * without conflicting with each other.
 */
class TripSegment extends Model
{
    protected $fillable = [
        'trip_id',
        'order_index',
        'start_stop',
        'end_stop',
        'seats_total',
        'seats_available',
        'price',
        'estimated_minutes',
    ];

    protected $casts = [
        'order_index'       => 'integer',
        'seats_total'       => 'integer',
        'seats_available'   => 'integer',
        'price'             => 'decimal:2',
        'estimated_minutes' => 'integer',
    ];

    // ---------------------------------------------------------------
    // Relationships
    // ---------------------------------------------------------------

    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    public function bookings(): BelongsToMany
    {
        return $this->belongsToMany(Booking::class, 'booking_segments')
            ->withPivot('seats')
            ->withTimestamps();
    }

    // ---------------------------------------------------------------
    // Helpers (encapsulation of seat math)
    // ---------------------------------------------------------------

    public function hasAvailableSeats(int $seats): bool
    {
        return $this->seats_available >= $seats;
    }

    /**
     * Reserve seats on this segment. Caller must wrap in a DB
     * transaction together with creating the booking row.
     */
    public function reserveSeats(int $seats): void
    {
        if (!$this->hasAvailableSeats($seats)) {
            throw new \RuntimeException(
                "Not enough seats on segment {$this->start_stop} -> {$this->end_stop}"
            );
        }
        $this->seats_available -= $seats;
        $this->save();
    }

    public function releaseSeats(int $seats): void
    {
        $this->seats_available = min(
            $this->seats_total,
            $this->seats_available + $seats
        );
        $this->save();
    }
}
