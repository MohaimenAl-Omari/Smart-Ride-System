<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Trip extends Model
{
    protected $fillable = [
        'driver_id',
        'origin',
        'destination',
        'departure_at',
        'seats_total',
        'seats_available',
        'min_passengers',
        'price_per_seat',
        'car_model',
        'car_plate',
        'notes',
        'status',
    ];

    protected $casts = [
        'departure_at'   => 'datetime',
        'seats_total'    => 'integer',
        'seats_available'=> 'integer',
        'min_passengers' => 'integer',
        'price_per_seat' => 'decimal:2',
    ];

    public function driver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function stops(): HasMany
    {
        return $this->hasMany(TripStop::class)->orderBy('order_index');
    }

    public function bookings(): HasMany
    {
        return $this->hasMany(Booking::class);
    }

    public function pendingBookings(): HasMany
    {
        return $this->hasMany(Booking::class)->where('status', 'pending');
    }

    public function acceptedBookings(): HasMany
    {
        return $this->hasMany(Booking::class)->where('status', 'accepted');
    }

    /**
     * Ride Segmentation feature.
     * Ordered list of legs between consecutive stops.
     */
    public function segments(): HasMany
    {
        return $this->hasMany(TripSegment::class)->orderBy('order_index');
    }

  
    public function orderedPoints(): array
    {
        $stops = $this->stops()->orderBy('order_index')->pluck('name')->all();
        if (!empty($stops) && $stops[0] === $this->origin
            && end($stops) === $this->destination) {
            return $stops;
        }
        return array_values(array_merge(
            [$this->origin],
            array_values(array_filter(
                $stops,
                fn ($n) => $n !== $this->origin && $n !== $this->destination
            )),
            [$this->destination]
        ));
    }
}
