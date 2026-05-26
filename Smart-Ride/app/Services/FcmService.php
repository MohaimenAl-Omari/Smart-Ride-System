<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\User;


class FcmService
{
    
    public static function notify(User $user, string $type, array $payload): AppNotification
    {
        return AppNotification::create([
            'user_id' => $user->id,
            'title'   => $payload['title'] ?? 'Smart Ride',
            'body'    => $payload['body']  ?? '',
            'type'    => $type,
            'data'    => $payload['data']  ?? [],
            'is_read' => false,
        ]);
    }

    public static function bookingCreated(User $driver, string $passengerName, string $route): void
    {
        self::notify($driver, 'booking_created', [
            'title' => 'New Booking Request',
            'body'  => "{$passengerName} has requested a seat on your trip ({$route}).",
        ]);
    }
    public static function bookingAccepted(User $passenger, string $driverName, string $route): void
    {
        self::notify($passenger, 'booking_accepted', [
            'title' => 'Booking Accepted',
            'body'  => "{$driverName} accepted your booking for {$route}.",
        ]);
    }

    public static function bookingRejected(User $passenger, string $route): void
    {
        self::notify($passenger, 'booking_rejected', [
            'title' => 'Booking Rejected',
            'body'  => "Your booking request for {$route} was not accepted.",
        ]);
    }

    public static function bookingCancelledByPassenger(User $driver, string $passengerName, string $route): void
    {
        self::notify($driver, 'booking_cancelled', [
            'title' => 'Booking Cancelled',
            'body'  => "{$passengerName} cancelled their booking for {$route}.",
        ]);
    }

    public static function tripCancelledByDriver(User $passenger, string $route): void
    {
        self::notify($passenger, 'trip_cancelled', [
            'title' => 'Trip Cancelled',
            'body'  => "Your trip ({$route}) has been cancelled by the driver.",
        ]);
    }
    public static function tripStarted(User $passenger, string $route): void
    {
        self::notify($passenger, 'trip_started', [
            'title' => 'Trip Started',
            'body'  => "Your trip ({$route}) has started. The driver is on the way!",
        ]);
    }
    public static function tripCompleted(User $passenger, string $driverName): void
    {
        self::notify($passenger, 'trip_completed', [
            'title' => 'Trip Completed',
            'body'  => "You have arrived! How was your ride with {$driverName}?",
        ]);
    }

    public static function driverRated(User $driver, int $stars, string $passengerName): void
    {
        self::notify($driver, 'driver_rated', [
            'title' => 'New Rating Received',
            'body'  => "{$passengerName} gave you {$stars}/5 stars.",
        ]);
    }

    public static function noShowPenalty(User $passenger, string $route, float $amount): void
    {
        self::notify($passenger, 'no_show_penalty', [
            'title' => 'No-Show Penalty Applied',
            'body'  => "You did not check in for your trip ({$route}). "
                     . number_format($amount, 2) . " JD has been added to your outstanding balance.",
        ]);
    }
}
