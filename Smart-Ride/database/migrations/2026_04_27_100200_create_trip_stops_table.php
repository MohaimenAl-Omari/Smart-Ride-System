<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trip_stops', function (Blueprint $table) {
            $table->id();
            $table->foreignId('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->string('name');
            $table->unsignedTinyInteger('order_index');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trip_stops');
    }
};
