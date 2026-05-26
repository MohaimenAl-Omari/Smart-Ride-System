<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class User extends Authenticatable
{
    use HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'phone',
        'password',
        'api_token',
        'role',
        'city',
        'image',
        'is_verified',
        'is_active',
        'balance',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'api_token',
    ];

    protected $casts = [
        'is_verified' => 'boolean',
        'is_active'   => 'boolean',
        'balance'     => 'decimal:2',
    ];

    protected $appends = [
        'rating_average',
        'ratings_count',
        'image_url',
    ];

    public function certificate(): HasOne
    {
        return $this->hasOne(DriverCertificate::class);
    }

    public function tripsAsDriver(): HasMany
    {
        return $this->hasMany(Trip::class, 'driver_id');
    }

    public function bookings(): HasMany
    {
        return $this->hasMany(Booking::class, 'passenger_id');
    }

    public function ratingsReceived(): HasMany
    {
        return $this->hasMany(TripRating::class, 'driver_id');
    }

    public function ratingsGiven(): HasMany
    {
        return $this->hasMany(TripRating::class, 'passenger_id');
    }

    public function contactMessages(): HasMany
    {
        return $this->hasMany(ContactMessage::class);
    }

    public static function registerUser(array $data): self
    {
        return self::create([
            'name'        => $data['name'],
            'email'       => $data['email'],
            'phone'       => $data['phone'],
            'password'    => Hash::make($data['password']),
            'role'        => $data['role'] ?? 'passenger',
            'city'        => $data['city'] ?? null,
            'is_active'   => ($data['role'] ?? 'passenger') === 'driver' ? false : true,
            'is_verified' => false,
        ]);
    }

    public static function loginUser(string $email, string $password)
    {
        $user = self::where('email', $email)->first();
        if (!$user || !Hash::check($password, $user->password)) {
            return null;
        }
        if (!$user->is_active) {
            return $user->role === 'driver' ? 'pending' : 'inactive';
        }
        return $user;
    }

    public function refreshApiToken(): string
    {
        $token = Str::random(64);
        $this->forceFill(['api_token' => hash('sha256', $token)])->save();
        return $token;
    }

    public static function findByApiToken(?string $plainToken): ?self
    {
        if (!$plainToken) {
            return null;
        }
        return self::where('api_token', hash('sha256', $plainToken))->first();
    }
    public function getRatingAverageAttribute(): float
    {
        if ($this->role !== 'driver') {
            return 0.0;
        }
        $avg = $this->ratingsReceived()->avg('stars');
        return $avg ? round((float) $avg, 2) : 0.0;
    }

    public function getRatingsCountAttribute(): int
    {
        if ($this->role !== 'driver') {
            return 0;
        }
        return (int) $this->ratingsReceived()->count();
    }

    public function getImageUrlAttribute(): ?string
    {
        if (!$this->image) {
            return null;
        }
        if (preg_match('#^https?://#', $this->image)) {
            return $this->image;
        }
        return url('storage/' . ltrim($this->image, '/'));
    }
}
