<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Adds three structured location fields to bookings.
 * The passenger fills these manually when booking a trip
 * so the driver knows exactly where to pick them up.
 *
 *   location_area      – neighbourhood / district  (required by the app)
 *   location_street    – street name               (optional)
 *   location_building  – building number / name    (optional)
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->string('location_area',     150)->nullable()->after('dropoff_stop');
            $table->string('location_street',   150)->nullable()->after('location_area');
            $table->string('location_building', 100)->nullable()->after('location_street');
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropColumn(['location_area', 'location_street', 'location_building']);
        });
    }
};
