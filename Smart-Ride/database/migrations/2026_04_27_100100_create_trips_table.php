<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trips', function (Blueprint $table) {
            $table->id();
            $table->foreignId('driver_id')->constrained('users')->cascadeOnDelete();
            $table->string('origin');
            $table->string('destination');
            $table->dateTime('departure_at');
            $table->unsignedTinyInteger('seats_total');
            $table->unsignedTinyInteger('seats_available');
            $table->unsignedTinyInteger('min_passengers')->default(1);
            $table->decimal('price_per_seat', 8, 2);
            $table->string('car_model')->nullable();
            $table->string('car_plate')->nullable();
            $table->text('notes')->nullable();
            $table->enum('status', ['scheduled', 'in_progress', 'completed', 'cancelled'])
                ->default('scheduled');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trips');
    }
};
