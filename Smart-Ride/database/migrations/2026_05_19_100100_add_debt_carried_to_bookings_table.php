<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            // Amount of prior no-show debt rolled into this booking's total_price.
            // 0.00 means no debt was carried; > 0 means the passenger owed this amount
            // from a previous no-show and it was included in the current total.
            $table->decimal('debt_carried', 10, 2)->default(0.00)->after('total_price');
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropColumn('debt_carried');
        });
    }
};
