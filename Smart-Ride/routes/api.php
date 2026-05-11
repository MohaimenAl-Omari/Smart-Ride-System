<?php

use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\ContactController;
use App\Http\Controllers\Api\RatingController;
use App\Http\Controllers\Api\SegmentController;
use App\Http\Controllers\Api\TripController;
use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;

// Public
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/upload-certificates', [AuthController::class, 'uploadCertificates']);

Route::middleware('api.auth')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    // Profile editing
    Route::post('/profile', [AuthController::class, 'updateProfile']);

    // Contact us
    Route::post('/contact', [ContactController::class, 'store']);

    // Trip browsing (any authenticated user)
    Route::get('/trips/search', [TripController::class, 'search']);
    Route::get('/trips/{trip}', [TripController::class, 'show']);

    // Ride Segmentation — read-only endpoints (any authenticated user)
    Route::get('/trips/{trip}/segments', [SegmentController::class, 'index']);
    Route::get('/segments/search', [SegmentController::class, 'search']);

    // Driver ratings
    Route::post('/ratings', [RatingController::class, 'store']);
    Route::get('/drivers/{driver}/ratings', [RatingController::class, 'forDriver']);

    // Driver-only endpoints
    Route::middleware('api.auth:driver')->group(function () {
        Route::get('/driver/trips', [TripController::class, 'myDriverTrips']);
        Route::get('/driver/trips/history', [TripController::class, 'driverHistory']);
        Route::post('/driver/trips', [TripController::class, 'store']);
        Route::post('/driver/trips/{trip}/cancel', [TripController::class, 'cancel']);
        Route::post('/driver/trips/{trip}/start', [TripController::class, 'start']);
        Route::post('/driver/trips/{trip}/complete', [TripController::class, 'complete']);

        Route::get('/driver/bookings', [BookingController::class, 'pendingForDriver']);
        Route::post('/driver/bookings/{booking}/accept', [BookingController::class, 'accept']);
        Route::post('/driver/bookings/{booking}/reject', [BookingController::class, 'reject']);

        // Ride Segmentation — driver-only
        Route::post('/driver/trips/{trip}/stops',              [SegmentController::class, 'addStop']);
        Route::post('/driver/trips/{trip}/segments/generate',  [SegmentController::class, 'generate']);
    });

    // Passenger-only endpoints
    Route::middleware('api.auth:passenger')->group(function () {
        Route::post('/bookings', [BookingController::class, 'store']);
        Route::get('/bookings/mine', [BookingController::class, 'myBookings']);
        Route::post('/bookings/{booking}/cancel', [BookingController::class, 'cancel']);
        Route::post('/bookings/{booking}/checkin', [BookingController::class, 'checkIn']);

        // Ride Segmentation — passenger-only
        Route::post('/segments/book',[SegmentController::class, 'book']);
        Route::post('/segments/bookings/{booking}/cancel',[SegmentController::class, 'cancel']);
    });
});
