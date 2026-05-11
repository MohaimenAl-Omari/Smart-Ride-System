// HTTP client for the Ride Segmentation feature. Talks to the new
// Laravel endpoints under /api/segments and /api/trips/{id}/segments.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constant.dart';
import '../models/trip_segment_model.dart';

class SegmentController {
  Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Map<String, String> _jsonHeaders(String token) => {
        ..._headers(token),
        'Content-Type': 'application/json',
      };

  /// GET /trips/{trip}/segments
  Future<List<TripSegmentModel>> listSegments(
      String token, int tripId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/trips/$tripId/segments'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['status'] == true) {
      final list = (data['segments'] as List?) ?? const [];
      return list
          .map((e) => TripSegmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  /// GET /segments/search?from=&to=&seats=
  Future<List<SegmentSearchResult>> search({
    required String token,
    required String from,
    required String to,
    int seats = 1,
  }) async {
    final uri = Uri.parse('$baseUrl/segments/search').replace(
      queryParameters: {
        'from': from,
        'to': to,
        'seats': '$seats',
      },
    );
    final res = await http.get(uri, headers: _headers(token));
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['status'] == true) {
      final results = (data['results'] as List?) ?? const [];
      return results
          .map((e) =>
              SegmentSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  /// POST /segments/book
  Future<SegmentActionResult> book({
    required String token,
    required int tripId,
    required String from,
    required String to,
    required int seats,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/segments/book'),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        'trip_id': tripId,
        'from': from,
        'to': to,
        'seats': seats,
      }),
    );
    final data = jsonDecode(res.body);
    final ok = res.statusCode == 200 && data['status'] == true;
    return SegmentActionResult(
      success: ok,
      message: data['message']?.toString() ??
          (ok ? 'Segment booked.' : 'Booking failed.'),
      booking: ok ? (data['booking'] as Map<String, dynamic>?) : null,
    );
  }

  /// POST /segments/bookings/{booking}/cancel
  Future<SegmentActionResult> cancel({
    required String token,
    required int bookingId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/segments/bookings/$bookingId/cancel'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    final ok = res.statusCode == 200 && data['status'] == true;
    return SegmentActionResult(
      success: ok,
      message: data['message']?.toString() ??
          (ok ? 'Cancelled.' : 'Cancellation failed.'),
    );
  }

  /// POST /driver/trips/{trip}/stops
  Future<SegmentActionResult> addStop({
    required String token,
    required int tripId,
    required String name,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/driver/trips/$tripId/stops'),
      headers: _jsonHeaders(token),
      body: jsonEncode({'name': name}),
    );
    final data = jsonDecode(res.body);
    final ok = res.statusCode == 200 && data['status'] == true;
    return SegmentActionResult(
      success: ok,
      message: data['message']?.toString() ??
          (ok ? 'Stop added.' : 'Failed to add stop.'),
    );
  }

  /// POST /driver/trips/{trip}/segments/generate
  Future<SegmentActionResult> generate({
    required String token,
    required int tripId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/driver/trips/$tripId/segments/generate'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    final ok = res.statusCode == 200 && data['status'] == true;
    return SegmentActionResult(
      success: ok,
      message: data['message']?.toString() ??
          (ok ? 'Segments generated.' : 'Failed to generate segments.'),
    );
  }
}
