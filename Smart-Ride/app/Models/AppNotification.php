<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AppNotification extends Model
{
    protected $table = 'notifications';

    protected $fillable = [
        'user_id',
        'title',
        'body',
        'type',
        'data',
        'is_read',
    ];

    protected $casts = [
        'data'    => 'array',   // automatic JSON encode/decode
        'is_read' => 'boolean',
    ];
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
    /** Filter to unread notifications only. */
    public function scopeUnread($query)
    {
        return $query->where('is_read', false);
    }
}
