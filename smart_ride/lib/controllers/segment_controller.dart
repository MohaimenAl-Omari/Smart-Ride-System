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

  Future<SegmentActionResult> book({
    required String token,
    required int tripId,
    required String from,
    required String to,
    required int seats,
  }) async {
    return bookWithLocation(
      token:  token,
      tripId: tripId,
      from:   from,
      to:     to,
      seats:  seats,
    );
  }

  Future<SegmentActionResult> bookWithLocation({
    required String token,
    required int tripId,
    required String from,
    required String to,
    required int seats,
    String? locationArea,
    String? locationStreet,
    String? locationBuilding,
  }) async {
    final payload = <String, dynamic>{
      'trip_id': tripId,
      'from':    from,
      'to':      to,
      'seats':   seats,
    };

    if (locationArea != null && locationArea.isNotEmpty) {
      payload['location_area'] = locationArea;
    }
    if (locationStreet != null && locationStreet.isNotEmpty) {
      payload['location_street'] = locationStreet;
    }
    if (locationBuilding != null && locationBuilding.isNotEmpty) {
      payload['location_building'] = locationBuilding;
    }

    final res = await http.post(
      Uri.parse('$baseUrl/segments/book'),
      headers: _jsonHeaders(token),
      body:    jsonEncode(payload),
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

  Future<bool> savePaymentMethod({
    required String token,
    required int bookingId,
    required String method,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/payment-method'),
        headers: _jsonHeaders(token),
        body: jsonEncode({'payment_method': method}),
      );
      final data = jsonDecode(res.body);
      return res.statusCode == 200 && data['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<SegmentActionResult> addStop({
    required String token,
    required int tripId,
    required String name,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/driver/trips/$tripId/stops'),
      headers: _jsonHeaders(token),
      body:    jsonEncode({'name': name}),
    );
    final data = jsonDecode(res.body);
    final ok = res.statusCode == 200 && data['status'] == true;
    return SegmentActionResult(
      success: ok,
      message: data['message']?.toString() ??
          (ok ? 'Stop added.' : 'Failed to add stop.'),
    );
  }

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
