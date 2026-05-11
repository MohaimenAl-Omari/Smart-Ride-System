<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bookings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->foreignId('passenger_id')->constrained('users')->cascadeOnDelete();
            $table->string('pickup_stop')->nullable();
            $table->string('dropoff_stop')->nullable();
            $table->unsignedTinyInteger('seats')->default(1);
            $table->decimal('total_price', 8, 2);
            $table->enum('status', [
                'pending',
                'accepted',
                'rejected',
                'cancelled',
                'completed',
            ])->default('pending');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bookings');
    }
};
