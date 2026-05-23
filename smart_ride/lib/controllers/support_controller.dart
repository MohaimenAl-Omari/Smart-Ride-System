import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constant.dart';

class ApiResult<T> {
  final bool success;
  final String message;
  final T? data;
  ApiResult({required this.success, required this.message, this.data});
}

class ContactController {
  Future<ApiResult<void>> send({
    required String token,
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/contact'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': email,
          'subject': subject,
          'message': message,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == true) {
        return ApiResult(success: true, message: data['message'] ?? 'Sent');
      }
      return ApiResult(
          success: false,
          message: data['message']?.toString() ?? 'Failed to send');
    } catch (e) {
      return ApiResult(success: false, message: 'Network error: $e');
    }
  }
}

/// A single driver rating row returned by the API.
class TripRatingModel {
  final int id;
  final int bookingId;
  final int tripId;
  final int passengerId;
  final int driverId;
  final int stars;
  final String? review;
  final String? passengerName;
  final String? passengerImage;

  TripRatingModel({
    required this.id,
    required this.bookingId,
    required this.tripId,
    required this.passengerId,
    required this.driverId,
    required this.stars,
    this.review,
    this.passengerName,
    this.passengerImage,
  });

  factory TripRatingModel.fromJson(Map<String, dynamic> json) {
    final passenger = json['passenger'] as Map<String, dynamic>?;
    return TripRatingModel(
      id: json['id'] ?? 0,
      bookingId: json['booking_id'] ?? 0,
      tripId: json['trip_id'] ?? 0,
      passengerId: json['passenger_id'] ?? 0,
      driverId: json['driver_id'] ?? 0,
      stars: int.tryParse(json['stars'].toString()) ?? 0,
      review: json['review'],
      passengerName: passenger?['name'],
      passengerImage: passenger?['image_url'] ?? passenger?['image'],
    );
  }
}
class DriverRatingsResponse {
  final double average;
  final int count;
  final List<TripRatingModel> ratings;
  DriverRatingsResponse({
    required this.average,
    required this.count,
    required this.ratings,
  });
}

class RatingController {
  Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
  Future<ApiResult<Map<String, dynamic>>> rate({
    required String token,
    required int bookingId,
    required int stars,
    String? review,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/ratings'),
        headers: {
          ..._headers(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'booking_id': bookingId,
          'stars': stars,
          if (review != null && review.isNotEmpty) 'review': review,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == true) {
        return ApiResult(
          success: true,
          message: data['message'] ?? 'Rated',
          data: data['driver'] is Map<String, dynamic>
              ? data['driver'] as Map<String, dynamic>
              : null,
        );
      }
      return ApiResult(
          success: false,
          message: data['message']?.toString() ?? 'Failed');
    } catch (e) {
      return ApiResult(success: false, message: 'Network error: $e');
    }
  }

  Future<DriverRatingsResponse?> forDriver({
    required String token,
    required int driverId,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/drivers/$driverId/ratings'),
        headers: _headers(token),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == true) {
        final list = (data['ratings'] as List?) ?? [];
        return DriverRatingsResponse(
          average: (data['rating_average'] is num)
              ? (data['rating_average'] as num).toDouble()
              : double.tryParse(data['rating_average'].toString()) ?? 0,
          count: int.tryParse(data['ratings_count'].toString()) ?? 0,
          ratings: list
              .map((e) => TripRatingModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
    } catch (_) {}
    return null;
  }
}
