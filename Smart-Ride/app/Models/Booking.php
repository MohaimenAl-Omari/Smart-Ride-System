<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Booking extends Model
{
    protected $fillable = [
        'trip_id',
        'passenger_id',
        'pickup_stop',
        'dropoff_stop',
        'seats',
        'total_price',
        'debt_carried',
        'status',
        'is_checked_in',
        'no_show',
        'location_area',
        'location_street',
        'location_building',
        'payment_method',
    ];

    protected $casts = [
        'seats'          => 'integer',
        'total_price'    => 'decimal:2',
        'debt_carried'   => 'decimal:2',
        'is_checked_in'  => 'boolean',
        'no_show'        => 'boolean',
    ];

    protected $appends = ['has_rating'];

    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    public function passenger(): BelongsTo
    {
        return $this->belongsTo(User::class, 'passenger_id');
    }

    public function rating(): HasOne
    {
        return $this->hasOne(TripRating::class);
    }

    public function getHasRatingAttribute(): bool
    {
        return $this->rating()->exists();
    }


    public function segments(): BelongsToMany
    {
        return $this->belongsToMany(TripSegment::class, 'booking_segments')
            ->withPivot('seats')
            ->withTimestamps()
            ->orderBy('order_index');
    }
}
