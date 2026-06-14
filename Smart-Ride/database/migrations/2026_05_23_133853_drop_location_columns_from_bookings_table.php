<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $toDrop = array_values(array_filter(
                ['pickup_lat', 'pickup_lng', 'pickup_address', 'dropoff_lat', 'dropoff_lng', 'dropoff_address'],
                fn ($col) => Schema::hasColumn('bookings', $col)
            ));
            if (!empty($toDrop)) {
                $table->dropColumn($toDrop);
            }
        });
    }
    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->decimal('pickup_lat', 10, 7)->nullable();
            $table->decimal('pickup_lng', 10, 7)->nullable();
            $table->string('pickup_address')->nullable();

            $table->decimal('dropoff_lat', 10, 7)->nullable();
            $table->decimal('dropoff_lng', 10, 7)->nullable();
            $table->string('dropoff_address')->nullable();
        });
    }
};
