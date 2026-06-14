import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_ride/controllers/rating_controller.dart';

MockClient _mockClient(Map<String, dynamic> body, {int status = 200}) =>
    MockClient((_) async => http.Response(jsonEncode(body), status));

void main() {
  // ──────────────────────────────────────────────────────────────
  // fetchDriverRatings
  // ──────────────────────────────────────────────────────────────
  group('RatingController.fetchDriverRatings', () {
    test('returns DriverRatingResponse on success', () async {
      final client = _mockClient({
        'status': true,
        'rating_average': 4.5,
        'ratings_count': 10,
        'ratings': [
          {
            'id': 1,
            'stars': 5,
            'review': 'Excellent!',
            'passenger': {'name': 'Ali', 'image_url': null},
            'created_at': '2026-06-01T10:00:00.000000Z',
          }
        ],
      });
      final ctrl = RatingController(client: client);
      final resp = await ctrl.fetchDriverRatings(token: 'tok', driverId: 2);

      expect(resp, isNotNull);
      expect(resp!.average, 4.5);
      expect(resp.count, 10);
      expect(resp.reviews.length, 1);
      expect(resp.reviews.first.stars, 5);
      expect(resp.reviews.first.passengerName, 'Ali');
    });

    test('returns null on auth failure (401)', () async {
      final client = _mockClient({'message': 'Unauthenticated.'}, status: 401);
      final ctrl = RatingController(client: client);
      final resp = await ctrl.fetchDriverRatings(token: 'bad', driverId: 2);

      expect(resp, isNull);
    });

    test('returns null when user is not a driver (400)', () async {
      final client = _mockClient(
        {'status': false, 'message': 'User is not a driver.'},
        status: 400,
      );
      final ctrl = RatingController(client: client);
      final resp = await ctrl.fetchDriverRatings(token: 'tok', driverId: 99);

      expect(resp, isNull);
    });

    test('returns empty reviews list when driver has no ratings', () async {
      final client = _mockClient({
        'status': true,
        'rating_average': 0,
        'ratings_count': 0,
        'ratings': [],
      });
      final ctrl = RatingController(client: client);
      final resp = await ctrl.fetchDriverRatings(token: 'tok', driverId: 2);

      expect(resp, isNotNull);
      expect(resp!.reviews, isEmpty);
      expect(resp.average, 0.0);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // submitRating
  // ──────────────────────────────────────────────────────────────
  group('RatingController.submitRating', () {
    test('returns success on 200', () async {
      final client = _mockClient({
        'status': true,
        'message': 'Thanks for rating!',
        'rating': {'id': 1, 'stars': 5},
        'driver': {'id': 2, 'rating_average': 5.0, 'ratings_count': 1},
      });
      final ctrl = RatingController(client: client);
      final result = await ctrl.submitRating(token: 'tok', bookingId: 5, stars: 5);

      expect(result.success, isTrue);
      expect(result.message, contains('rating'));
    });

    test('returns failure on invalid stars (400)', () async {
      final client = _mockClient(
        {'status': false, 'message': 'The stars field must not be greater than 5.'},
        status: 400,
      );
      final ctrl = RatingController(client: client);
      final result = await ctrl.submitRating(token: 'tok', bookingId: 5, stars: 6);

      expect(result.success, isFalse);
    });

    test('returns failure on duplicate rating (400)', () async {
      final client = _mockClient(
        {'status': false, 'message': 'You already rated this trip.'},
        status: 400,
      );
      final ctrl = RatingController(client: client);
      final result = await ctrl.submitRating(token: 'tok', bookingId: 5, stars: 4);

      expect(result.success, isFalse);
      expect(result.message, contains('already rated'));
    });

    test('returns failure when booking is not completed (400)', () async {
      final client = _mockClient(
        {'status': false, 'message': 'You can only rate after the trip completes.'},
        status: 400,
      );
      final ctrl = RatingController(client: client);
      final result = await ctrl.submitRating(token: 'tok', bookingId: 5, stars: 3);

      expect(result.success, isFalse);
    });

    test('returns failure when passenger rates from wrong booking (403)', () async {
      final client = _mockClient(
        {'status': false, 'message': 'You can only rate your own bookings.'},
        status: 403,
      );
      final ctrl = RatingController(client: client);
      final result = await ctrl.submitRating(token: 'tok', bookingId: 99, stars: 3);

      expect(result.success, isFalse);
    });

    test('includes review in request and succeeds', () async {
      final client = _mockClient({
        'status': true,
        'message': 'Thanks for rating!',
        'rating': {'id': 2, 'stars': 4, 'review': 'Good driver'},
        'driver': {'id': 2, 'rating_average': 4.0, 'ratings_count': 1},
      });
      final ctrl = RatingController(client: client);
      final result = await ctrl.submitRating(
        token: 'tok',
        bookingId: 5,
        stars: 4,
        review: 'Good driver',
      );

      expect(result.success, isTrue);
    });

    test('returns network error message on exception', () async {
      final client = MockClient((_) async => throw Exception('Network down'));
      final ctrl = RatingController(client: client);
      final result = await ctrl.submitRating(token: 'tok', bookingId: 5, stars: 5);

      expect(result.success, isFalse);
      expect(result.message, contains('Network error'));
    });
  });
}
