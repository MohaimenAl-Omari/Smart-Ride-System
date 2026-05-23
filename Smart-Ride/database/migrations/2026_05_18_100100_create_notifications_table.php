<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Feature: Notification System (F5).
 *
 * Every notification triggered by a system event (new booking, trip
 * started, rating received, etc.) gets persisted here so users can
 * review their notification history even after dismissing the push alert.
 *
 * Push delivery is handled separately by FcmService. This table is the
 * server-side inbox — think of it as the "notification bell" storage.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();

            // The user who should receive this notification.
            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            // Short push-notification title (e.g. "Booking Accepted").
            $table->string('title', 120);

            // Longer description shown in the notification drawer /
            // notification history screen.
            $table->string('body', 500);

            // Machine-readable type used by the Flutter app to decide
            // which screen to navigate to on tap.
            // Examples: booking_accepted, trip_started, driver_rated …
            $table->string('type', 60)->index();

            // Optional JSON payload for deep-linking (trip_id, booking_id, …).
            $table->json('data')->nullable();

            // False until the user opens/taps the notification.
            $table->boolean('is_read')->default(false);

            $table->timestamps();

            // Useful for "unread count" queries.
            $table->index(['user_id', 'is_read']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
