<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Persisted notification record.
 *
 * Every system event that deserves a push alert also creates one of
 * these rows so users can browse their notification history and the
 * Flutter app can show an unread-count badge.
 *
 * Named AppNotification to avoid collision with Laravel's built-in
 * Illuminate\Notifications\Notification class.
 */
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

    // ---------------------------------------------------------------
    // Relationships
    // ---------------------------------------------------------------

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    // ---------------------------------------------------------------
    // Scopes
    // ---------------------------------------------------------------

    /** Filter to unread notifications only. */
    public function scopeUnread($query)
    {
        return $query->where('is_read', false);
    }
}
