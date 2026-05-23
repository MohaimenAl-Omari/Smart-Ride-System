<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\User;

/**
 * NotificationService (kept as FcmService for backward compatibility).
 *
 * Responsibilities:
 *   1. Create a persisted AppNotification row in the notifications table.
 *   2. The Flutter app picks up new notifications by polling
 *      GET /api/notifications every 30 seconds.
 *
 * No Firebase / FCM dependency — all delivery is DB-driven.
 *
 * Usage example:
 *   FcmService::notify($passenger, 'booking_accepted', [
 *       'title' => 'Booking Accepted',
 *       'body'  => 'Your booking for Irbid → Amman was accepted.',
 *       'data'  => ['booking_id' => 42],
 *   ]);
 */
class FcmService
{
    // ---------------------------------------------------------------
    // Public API
    // ---------------------------------------------------------------

    /**
     * Store a notification record in the database.
     *
     * @param  User                $user    The recipient.
     * @param  string              $type    Machine-readable event type.
     * @param  array<string,mixed> $payload {title, body, data?}
     */
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

    // ---------------------------------------------------------------
    // Predefined notification helpers (called by controllers)
    // ---------------------------------------------------------------

    /** Driver: a new passenger booked one of your trips. */
    public static function bookingCreated(User $driver, string $passengerName, string $route): void
    {
        self::notify($driver, 'booking_created', [
            'title' => 'New Booking Request',
            'body'  => "{$passengerName} has requested a seat on your trip ({$route}).",
        ]);
    }

    /** Passenger: the driver accepted your booking. */
    public static function bookingAccepted(User $passenger, string $driverName, string $route): void
    {
        self::notify($passenger, 'booking_accepted', [
            'title' => 'Booking Accepted',
            'body'  => "{$driverName} accepted your booking for {$route}.",
        ]);
    }

    /** Passenger: the driver rejected your booking. */
    public static function bookingRejected(User $passenger, string $route): void
    {
        self::notify($passenger, 'booking_rejected', [
            'title' => 'Booking Rejected',
            'body'  => "Your booking request for {$route} was not accepted.",
        ]);
    }

    /** Driver: a passenger cancelled their booking. */
    public static function bookingCancelledByPassenger(User $driver, string $passengerName, string $route): void
    {
        self::notify($driver, 'booking_cancelled', [
            'title' => 'Booking Cancelled',
            'body'  => "{$passengerName} cancelled their booking for {$route}.",
        ]);
    }

    /** Passenger: the trip you booked has been cancelled by the driver. */
    public static function tripCancelledByDriver(User $passenger, string $route): void
    {
        self::notify($passenger, 'trip_cancelled', [
            'title' => 'Trip Cancelled',
            'body'  => "Your trip ({$route}) has been cancelled by the driver.",
        ]);
    }

    /** Passenger: your trip has started — driver is on the way. */
    public static function tripStarted(User $passenger, string $route): void
    {
        self::notify($passenger, 'trip_started', [
            'title' => 'Trip Started',
            'body'  => "Your trip ({$route}) has started. The driver is on the way!",
        ]);
    }

    /** Passenger: trip completed — please rate your driver. */
    public static function tripCompleted(User $passenger, string $driverName): void
    {
        self::notify($passenger, 'trip_completed', [
            'title' => 'Trip Completed',
            'body'  => "You have arrived! How was your ride with {$driverName}?",
        ]);
    }

    /** Driver: a passenger just rated you. */
    public static function driverRated(User $driver, int $stars, string $passengerName): void
    {
        self::notify($driver, 'driver_rated', [
            'title' => 'New Rating Received',
            'body'  => "{$passengerName} gave you {$stars}/5 stars.",
        ]);
    }

    /**
     * Passenger: they didn't check in before the trip departed — a debt
     * equal to their booking price has been added to their account.
     *
     * @param  User   $passenger  The no-show passenger.
     * @param  string $route      Human-readable "Origin → Destination".
     * @param  float  $amount     The booking price that became the debt.
     */
    public static function noShowPenalty(User $passenger, string $route, float $amount): void
    {
        self::notify($passenger, 'no_show_penalty', [
            'title' => 'No-Show Penalty Applied',
            'body'  => "You did not check in for your trip ({$route}). "
                     . number_format($amount, 2) . " JD has been added to your outstanding balance.",
        ]);
    }
}
