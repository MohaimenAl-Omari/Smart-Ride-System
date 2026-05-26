<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

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

    public function hasAvailableSeats(int $seats): bool
    {
        return $this->seats_available >= $seats;
    }


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
