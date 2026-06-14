import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ride/models/driver_rating_model.dart';

void main() {
  group('DriverRatingResponse.fromJson', () {
    test('parses average and count', () {
      final json = {
        'status': true,
        'rating_average': 4.5,
        'ratings_count': 8,
        'ratings': [],
      };
      final resp = DriverRatingResponse.fromJson(json);
      expect(resp.average, 4.5);
      expect(resp.count, 8);
      expect(resp.reviews, isEmpty);
    });

    test('parses average from string', () {
      final json = {
        'status': true,
        'rating_average': '3.75',
        'ratings_count': '4',
        'ratings': [],
      };
      final resp = DriverRatingResponse.fromJson(json);
      expect(resp.average, 3.75);
      expect(resp.count, 4);
    });

    test('parses ratings list', () {
      final json = {
        'status': true,
        'rating_average': 5.0,
        'ratings_count': 1,
        'ratings': [
          {
            'id': 1,
            'stars': 5,
            'review': 'Great!',
            'passenger': {'name': 'Hana', 'image_url': null},
            'created_at': '2026-06-01T10:00:00.000000Z',
          }
        ],
      };
      final resp = DriverRatingResponse.fromJson(json);
      expect(resp.reviews.length, 1);
      expect(resp.reviews.first.stars, 5);
      expect(resp.reviews.first.review, 'Great!');
      expect(resp.reviews.first.passengerName, 'Hana');
    });

    test('handles zero values gracefully', () {
      final json = {
        'status': true,
        'rating_average': 0,
        'ratings_count': 0,
        'ratings': [],
      };
      final resp = DriverRatingResponse.fromJson(json);
      expect(resp.average, 0.0);
      expect(resp.count, 0);
    });
  });

  group('DriverReviewModel.fromJson', () {
    test('parses all review fields', () {
      final json = {
        'id': 7,
        'stars': 4,
        'review': 'Good driver.',
        'passenger': {'name': 'Omar', 'image_url': 'http://example.com/img.jpg'},
        'created_at': '2026-05-15T09:30:00.000000Z',
      };
      final review = DriverReviewModel.fromJson(json);
      expect(review.id, 7);
      expect(review.stars, 4);
      expect(review.review, 'Good driver.');
      expect(review.passengerName, 'Omar');
      expect(review.passengerImage, 'http://example.com/img.jpg');
      expect(review.createdAt!.month, 5);
    });

    test('handles null review text', () {
      final json = {
        'id': 8,
        'stars': 3,
        'review': null,
        'passenger': {'name': 'Sara'},
        'created_at': null,
      };
      final review = DriverReviewModel.fromJson(json);
      expect(review.review, isNull);
      expect(review.createdAt, isNull);
    });

    test('handles missing passenger gracefully', () {
      final json = {
        'id': 9,
        'stars': 5,
        'review': null,
        'passenger': null,
        'created_at': null,
      };
      final review = DriverReviewModel.fromJson(json);
      expect(review.passengerName, isNull);
      expect(review.passengerImage, isNull);
    });
  });
}
