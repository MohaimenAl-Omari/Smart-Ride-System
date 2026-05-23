import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constant.dart';
import '../models/driver_rating_model.dart';

class RatingController {
  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };


  Future<DriverRatingResponse?> fetchDriverRatings({
    required String token,
    required int driverId,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/drivers/$driverId/ratings'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == true) {
          return DriverRatingResponse.fromJson(data);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<({bool success, String message})> submitRating({
    required String token,
    required int bookingId,
    required int stars,
    String? review,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/ratings'),
        headers: _headers(token),
        body: jsonEncode({
          'booking_id': bookingId,
          'stars':      stars,
          if (review != null && review.isNotEmpty) 'review': review,
        }),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final ok = res.statusCode == 200 && data['status'] == true;
      return (
        success: ok,
        message: data['message']?.toString() ?? (ok ? 'Rating submitted.' : 'Failed.'),
      );
    } catch (_) {
      return (success: false, message: 'Network error.');
    }
  }
}
