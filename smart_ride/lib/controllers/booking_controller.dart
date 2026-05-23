import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constant.dart';
import '../models/booking_model.dart';

class BookingController {
  Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<BookingResult> create({
    required String token,
    required int tripId,
    required int seats,
    String? pickupStop,
    String? dropoffStop,
  }) async {
    final body = <String, dynamic>{
      'trip_id': tripId,
      'seats': seats,
      if (pickupStop != null && pickupStop.isNotEmpty) 'pickup_stop': pickupStop,
      if (dropoffStop != null && dropoffStop.isNotEmpty) 'dropoff_stop': dropoffStop,
    };
    final res = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: {..._headers(token), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['status'] == true) {
      return BookingResult(success: true, message: data['message'] ?? 'Booked');
    }
    return BookingResult(success: false, message: data['message'] ?? 'Failed');
  }

  Future<List<BookingModel>> myBookings(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/bookings/mine'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['status'] == true) {
      final list = (data['bookings'] as List?) ?? [];
      return list.map((e) => BookingModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<BookingModel>> driverBookings(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/driver/bookings'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['status'] == true) {
      final list = (data['bookings'] as List?) ?? [];
      return list.map((e) => BookingModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> accept(String token, int bookingId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/driver/bookings/$bookingId/accept'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    return res.statusCode == 200 && data['status'] == true;
  }

  Future<bool> reject(String token, int bookingId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/driver/bookings/$bookingId/reject'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    return res.statusCode == 200 && data['status'] == true;
  }

  Future<bool> cancel(String token, int bookingId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    return res.statusCode == 200 && data['status'] == true;
  }

  Future<BookingResult> checkIn(String token, int bookingId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/checkin'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    final ok = res.statusCode == 200 && data['status'] == true;
    return BookingResult(
      success: ok,
      message: data['message']?.toString() ??
          (ok ? 'Checked in.' : 'Check-in failed.'),
    );
  }

  Future<BookingResult> driverCheckIn(String token, int bookingId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/driver/bookings/$bookingId/checkin'),
      headers: _headers(token),
    );
    final data = jsonDecode(res.body);
    final ok = res.statusCode == 200 && data['status'] == true;
    return BookingResult(
      success: ok,
      message: data['message']?.toString() ??
          (ok ? 'Passenger checked in.' : 'Check-in failed.'),
    );
  }
}

class BookingResult {
  final bool success;
  final String message;
  BookingResult({required this.success, required this.message});
}
