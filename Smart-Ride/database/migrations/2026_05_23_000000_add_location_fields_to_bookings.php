<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            if (!Schema::hasColumn('bookings', 'location_area')) {
                $table->string('location_area', 150)->nullable()->after('dropoff_stop');
            }
            if (!Schema::hasColumn('bookings', 'location_street')) {
                $table->string('location_street', 150)->nullable()->after('location_area');
            }
            if (!Schema::hasColumn('bookings', 'location_building')) {
                $table->string('location_building', 100)->nullable()->after('location_street');
            }
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropColumn(array_filter([
                Schema::hasColumn('bookings', 'location_area')     ? 'location_area'     : null,
                Schema::hasColumn('bookings', 'location_street')   ? 'location_street'   : null,
                Schema::hasColumn('bookings', 'location_building') ? 'location_building' : null,
            ]));
        });
    }
};
