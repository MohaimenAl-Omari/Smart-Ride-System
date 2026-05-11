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
        'status',
        'checked_in_at',
        'no_show',
    ];

    protected $casts = [
        'seats'         => 'integer',
        'total_price'   => 'decimal:2',
        'checked_in_at' => 'datetime',
        'no_show'       => 'boolean',
    ];

    protected $appends = ['has_rating', 'is_checked_in'];


    public function getIsCheckedInAttribute(): bool
    {
        return $this->checked_in_at !== null;
    }

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
