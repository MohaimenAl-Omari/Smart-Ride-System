<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            // Drop the old timestamp column
            $table->dropColumn('checked_in_at');

            // Add boolean flag (1 = checked in, 0 = not checked in)
            $table->boolean('is_checked_in')->default(0)->after('status');
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropColumn('is_checked_in');
            $table->timestamp('checked_in_at')->nullable()->after('status');
        });
    }
};
