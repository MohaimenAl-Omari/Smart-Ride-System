<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Driver ratings submitted by passengers after a completed trip.
 *
 * The unique compound key (booking_id, passenger_id) prevents a
 * passenger from rating the same booking twice. We also keep
 * driver_id and trip_id for fast lookup when computing a driver's
 * average rating.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trip_ratings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained('bookings')->cascadeOnDelete();
            $table->foreignId('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->foreignId('passenger_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('driver_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedTinyInteger('stars'); 
            $table->text('review')->nullable();
            $table->timestamps();

            $table->unique(['booking_id', 'passenger_id'], 'one_rating_per_booking');
            $table->index(['driver_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trip_ratings');
    }
};
