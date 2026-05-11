// Ride Segmentation - data classes mirroring the Laravel JSON shapes:
//   GET /api/trips/{id}/segments
//   GET /api/segments/search?from=&to=&seats=
//   POST /api/segments/book
//
// These models intentionally stay simple and immutable so they can be
// used across screens without controller coupling.

import 'trip_model.dart';

class TripSegmentModel {
  final int id;
  final int tripId;
  final int orderIndex;
  final String startStop;
  final String endStop;
  final int seatsTotal;
  final int seatsAvailable;
  final double price;
  final int estimatedMinutes;

  const TripSegmentModel({
    required this.id,
    required this.tripId,
    required this.orderIndex,
    required this.startStop,
    required this.endStop,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.price,
    required this.estimatedMinutes,
  });

  factory TripSegmentModel.fromJson(Map<String, dynamic> json) {
    return TripSegmentModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      tripId: int.tryParse((json['trip_id'] ?? 0).toString()) ?? 0,
      orderIndex: int.tryParse((json['order_index'] ?? 0).toString()) ?? 0,
      startStop: (json['start_stop'] ?? '').toString(),
      endStop: (json['end_stop'] ?? '').toString(),
      seatsTotal: int.tryParse((json['seats_total'] ?? 0).toString()) ?? 0,
      seatsAvailable:
          int.tryParse((json['seats_available'] ?? 0).toString()) ?? 0,
      price: double.tryParse((json['price'] ?? 0).toString()) ?? 0.0,
      estimatedMinutes:
          int.tryParse((json['estimated_minutes'] ?? 0).toString()) ?? 0,
    );
  }

  bool get hasSeats => seatsAvailable > 0;

  @override
  String toString() =>
      '$startStop -> $endStop ($seatsAvailable/$seatsTotal, JOD$price, ${estimatedMinutes}m)';
}

/// A single hit from the segment search endpoint: the trip plus the
/// specific legs that make up the requested route and their totals.
class SegmentSearchResult {
  final TripModel trip;
  final List<TripSegmentModel> route;
  final double totalPrice;
  final int totalMinutes;
  final int seatsRequested;

  const SegmentSearchResult({
    required this.trip,
    required this.route,
    required this.totalPrice,
    required this.totalMinutes,
    required this.seatsRequested,
  });

  factory SegmentSearchResult.fromJson(Map<String, dynamic> json) {
    final tripJson = (json['trip'] as Map<String, dynamic>?) ?? const {};
    final routeJson = (json['route'] as List?) ?? const [];

    return SegmentSearchResult(
      trip: TripModel.fromJson(tripJson),
      route: routeJson
          .map((e) =>
              TripSegmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPrice:
          double.tryParse((json['total_price'] ?? 0).toString()) ?? 0.0,
      totalMinutes:
          int.tryParse((json['total_minutes'] ?? 0).toString()) ?? 0,
      seatsRequested:
          int.tryParse((json['seats_requested'] ?? 1).toString()) ?? 1,
    );
  }
}

/// API call result wrapper for create/cancel actions.
class SegmentActionResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? booking;

  const SegmentActionResult({
    required this.success,
    required this.message,
    this.booking,
  });
}
