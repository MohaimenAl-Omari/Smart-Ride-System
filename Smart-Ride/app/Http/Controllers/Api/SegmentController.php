<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Trip;
use App\Services\FcmService;
use App\Services\TripSegmentationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use InvalidArgumentException;
use RuntimeException;

/**
 * HTTP layer for the Ride Segmentation feature.
 *
 * Routes (added in routes/api.php):
 *   GET  /api/trips/{trip}/segments
 *   POST /api/driver/trips/{trip}/segments/generate
 *   POST /api/driver/trips/{trip}/stops          (add an intermediate stop)
 *   GET  /api/segments/search?from=&to=&seats=
 *   POST /api/segments/book                       (passenger)
 *   POST /api/segments/bookings/{booking}/cancel  (passenger)
 */
class SegmentController extends Controller
{
    public function __construct(private TripSegmentationService $segments) {}

    /** GET /trips/{trip}/segments */
    public function index(Trip $trip): JsonResponse
    {
        return response()->json([
            'status'   => true,
            'trip_id'  => $trip->id,
            'segments' => $trip->segments()->orderBy('order_index')->get(),
        ]);
    }

    /** POST /driver/trips/{trip}/segments/generate */
    public function generate(Request $request, Trip $trip): JsonResponse
    {
        $user = $request->user();
        if ($trip->driver_id !== $user->id) {
            return response()->json([
                'status'  => false,
                'message' => 'You do not own this trip.',
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'segment_prices'   => 'nullable|array',
            'segment_prices.*' => 'numeric|min:0',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
            ], 400);
        }

        $segmentPrices = array_map(
            'floatval',
            $request->input('segment_prices', [])
        );

        try {
            $segments = $this->segments->generateSegments($trip, $segmentPrices);
        } catch (RuntimeException $e) {
            return response()->json([
                'status'  => false,
                'message' => $e->getMessage(),
            ], 400);
        }

        return response()->json([
            'status'   => true,
            'message'  => 'Segments generated.',
            'segments' => $segments,
        ]);
    }

    /** POST /driver/trips/{trip}/stops */
    public function addStop(Request $request, Trip $trip): JsonResponse
    {
        $user = $request->user();
        if ($trip->driver_id !== $user->id) {
            return response()->json([
                'status'  => false,
                'message' => 'You do not own this trip.',
            ], 403);
        }
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:120',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
            ], 400);
        }

        try {
            $stop = $this->segments->addStop($trip, $request->string('name'));
        } catch (InvalidArgumentException $e) {
            return response()->json([
                'status'  => false,
                'message' => $e->getMessage(),
            ], 400);
        }

        return response()->json([
            'status'  => true,
            'message' => 'Stop added.',
            'stop'    => $stop,
            'trip'    => $trip->fresh(['stops', 'segments']),
        ]);
    }

    /** GET /segments/search?from=&to=&seats= */
    public function search(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'from'  => 'required|string|max:120',
            'to'    => 'required|string|max:120',
            'seats' => 'nullable|integer|min:1|max:10',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
            ], 400);
        }

        $seats = (int) ($request->input('seats') ?? 1);
        $trips = $this->segments->searchAvailableTrips(
            (string) $request->string('from'),
            (string) $request->string('to'),
            $seats,
        );

        // Enrich each match with the relevant route + computed totals
        // so the Flutter UI can render directly.
        $results = $trips->map(function ($trip) use ($request, $seats) {
            $route = $this->segments->segmentsBetween(
                $trip,
                (string) $request->string('from'),
                (string) $request->string('to'),
            );
            return [
                'trip'            => $trip,
                'route'           => $route,
                'total_price'     => $route->sum(fn ($s) => (float) $s->price) * $seats,
                'total_minutes'   => $route->sum(fn ($s) => (int) $s->estimated_minutes),
                'seats_requested' => $seats,
            ];
        });

        return response()->json([
            'status'  => true,
            'results' => $results,
        ]);
    }

    /** POST /segments/book */
    public function book(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'trip_id'         => 'required|integer|exists:trips,id',
            'from'            => 'required|string|max:120',
            'to'              => 'required|string|max:120',
            'seats'           => 'required|integer|min:1|max:10',
            // Passenger pickup location — three structured text fields.
            'location_area'     => 'nullable|string|max:150',
            'location_street'   => 'nullable|string|max:150',
            'location_building' => 'nullable|string|max:100',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
            ], 400);
        }

        $trip = Trip::findOrFail((int) $request->input('trip_id'));
        $passenger = $request->user();

        try {
            $booking = $this->segments->bookSegment(
                $passenger,
                $trip,
                (string) $request->string('from'),
                (string) $request->string('to'),
                (int) $request->integer('seats'),
                $request->input('location_area')     ?: null,
                $request->input('location_street')   ?: null,
                $request->input('location_building') ?: null,
            );
        } catch (InvalidArgumentException $e) {
            return response()->json([
                'status'  => false,
                'message' => $e->getMessage(),
            ], 400);
        } catch (RuntimeException $e) {
            return response()->json([
                'status'  => false,
                'message' => $e->getMessage(),
            ], 409); // conflict (overlap / no seats)
        }

        // Notify the driver about the new segment booking.
        $route = "{$request->string('from')} → {$request->string('to')}";
        FcmService::bookingCreated($trip->driver, $passenger->name, $route);

        return response()->json([
            'status'  => true,
            'message' => 'Segment booked.',
            'booking' => $booking->fresh('segments'),
        ]);
    }

    /** POST /segments/bookings/{booking}/cancel */
    public function cancel(Request $request, Booking $booking): JsonResponse
    {
        if ($booking->passenger_id !== $request->user()->id) {
            return response()->json([
                'status'  => false,
                'message' => 'You do not own this booking.',
            ], 403);
        }

        try {
            $booking = $this->segments->cancelBooking($booking);
        } catch (InvalidArgumentException $e) {
            return response()->json([
                'status'  => false,
                'message' => $e->getMessage(),
            ], 400);
        }

        return response()->json([
            'status'  => true,
            'message' => 'Booking cancelled.',
            'booking' => $booking,
        ]);
    }
}
