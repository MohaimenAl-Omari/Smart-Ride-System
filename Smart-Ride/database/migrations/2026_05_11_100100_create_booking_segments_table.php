<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Pivot linking a booking to every TripSegment it occupies.
 *
 * A booking from Irbid → Aqaba on a 2-segment trip creates 2 rows;
 * a booking from Amman → Aqaba creates 1 row. The seat reservation is
 * done segment-by-segment in the service.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('booking_segments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')
                ->constrained('bookings')
                ->cascadeOnDelete();
            $table->foreignId('trip_segment_id')
                ->constrained('trip_segments')
                ->cascadeOnDelete();
            $table->unsignedTinyInteger('seats');
            $table->timestamps();

            $table->unique(['booking_id', 'trip_segment_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('booking_segments');
    }
};
