<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DriverCertificate extends Model
{
    protected $fillable = [
        'user_id',
        'license_path',
        'non_conviction_path',
        'medical_path',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
