<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trip_segments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('trip_id')
                ->constrained('trips')
                ->cascadeOnDelete();

            // 0-based position of this segment within the trip.
            $table->unsignedTinyInteger('order_index');

            $table->string('start_stop');
            $table->string('end_stop');

            $table->unsignedTinyInteger('seats_total');
            $table->unsignedTinyInteger('seats_available');

            $table->decimal('price', 8, 2);
            $table->unsignedSmallInteger('estimated_minutes');

            $table->timestamps();

            $table->unique(['trip_id', 'order_index']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trip_segments');
    }
};
