<?php

use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\BookingController;
use App\Http\Controllers\Admin\ContactController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\TripController;
use App\Http\Controllers\Admin\UserController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect()->route('admin.login');
});

Route::prefix('admin')->group(function () {
    Route::get('/login', [AdminAuthController::class, 'showLogin'])->name('admin.login');
    Route::post('/login', [AdminAuthController::class, 'login'])->name('admin.login.submit');

    Route::middleware('admin')->group(function () {
        Route::post('/logout', [AdminAuthController::class, 'logout'])->name('admin.logout');

        Route::get('/', [DashboardController::class, 'index'])->name('admin.dashboard');

        Route::get('/drivers/pending', [UserController::class, 'pendingDrivers'])
            ->name('admin.drivers.pending');
        Route::post('/drivers/{user}/approve', [DashboardController::class, 'approve'])
            ->name('admin.drivers.approve');
        Route::post('/drivers/{user}/reject', [DashboardController::class, 'reject'])
            ->name('admin.drivers.reject');
        Route::get('/drivers/{user}/certificate/{type}', [DashboardController::class, 'certificate'])
            ->name('admin.drivers.certificate');

        Route::get('/users', [UserController::class, 'index'])->name('admin.users');
        Route::post('/users/{user}/toggle', [UserController::class, 'toggleActive'])
            ->name('admin.users.toggle');
        Route::delete('/users/{user}', [UserController::class, 'destroy'])
            ->name('admin.users.destroy');

        Route::get('/trips', [TripController::class, 'index'])->name('admin.trips');
        Route::get('/trips/{trip}', [TripController::class, 'show'])->name('admin.trips.show');

        Route::get('/bookings', [BookingController::class, 'index'])->name('admin.bookings');

        // F-table "Management reports" — admin handles user complaints
        Route::get('/contact', [ContactController::class, 'index'])->name('admin.contact');
        Route::post('/contact/{message}', [ContactController::class, 'updateStatus'])
            ->name('admin.contact.update');
    });
});
