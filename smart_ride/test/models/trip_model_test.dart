import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ride/models/trip_model.dart';

void main() {
  Map<String, dynamic> sampleJson() => {
        'id': 10,
        'driver_id': 2,
        'origin': 'Irbid',
        'destination': 'Amman',
        'departure_at': '2026-07-01T08:00:00.000000Z',
        'seats_total': 4,
        'seats_available': 3,
        'min_passengers': 1,
        'price_per_seat': '10.00',
        'car_model': 'Toyota Corolla',
        'car_plate': 'A-12345',
        'notes': 'No smoking',
        'status': 'scheduled',
        'driver': {
          'id': 2,
          'name': 'Sami Driver',
          'phone': '0790002222',
          'rating_average': 4.5,
          'ratings_count': 10,
        },
        'stops': [
          {'name': 'Irbid', 'order_index': 0},
          {'name': 'Zarqa', 'order_index': 1},
          {'name': 'Amman', 'order_index': 2},
        ],
        'bookings': [],
      };

  group('TripModel.fromJson', () {
    test('parses all core fields', () {
      final trip = TripModel.fromJson(sampleJson());

      expect(trip.id, 10);
      expect(trip.driverId, 2);
      expect(trip.origin, 'Irbid');
      expect(trip.destination, 'Amman');
      expect(trip.seatsTotal, 4);
      expect(trip.seatsAvailable, 3);
      expect(trip.minPassengers, 1);
      expect(trip.pricePerSeat, 10.00);
      expect(trip.carModel, 'Toyota Corolla');
      expect(trip.carPlate, 'A-12345');
      expect(trip.notes, 'No smoking');
      expect(trip.status, 'scheduled');
    });

    test('parses driver info', () {
      final trip = TripModel.fromJson(sampleJson());
      expect(trip.driverName, 'Sami Driver');
      expect(trip.driverPhone, '0790002222');
      expect(trip.driverRatingAverage, 4.5);
      expect(trip.driverRatingsCount, 10);
    });

    test('parses departure_at as DateTime', () {
      final trip = TripModel.fromJson(sampleJson());
      expect(trip.departureAt, isA<DateTime>());
      expect(trip.departureAt.year, 2026);
      expect(trip.departureAt.month, 7);
    });

    test('intermediate stops exclude origin and destination', () {
      final trip = TripModel.fromJson(sampleJson());
      // Zarqa is intermediate; Irbid and Amman are endpoints
      expect(trip.stops, ['Zarqa']);
    });

    test('no intermediate stops when only origin and destination', () {
      final json = {
        ...sampleJson(),
        'stops': [
          {'name': 'Irbid', 'order_index': 0},
          {'name': 'Amman', 'order_index': 1},
        ],
      };
      final trip = TripModel.fromJson(json);
      expect(trip.stops, isEmpty);
    });

    test('handles missing driver gracefully', () {
      final json = {...sampleJson(), 'driver': null};
      final trip = TripModel.fromJson(json);
      expect(trip.driverName, isNull);
      expect(trip.driverPhone, isNull);
      expect(trip.driverRatingAverage, 0.0);
    });

    test('handles missing stops gracefully', () {
      final json = {...sampleJson(), 'stops': null};
      final trip = TripModel.fromJson(json);
      expect(trip.stops, isEmpty);
    });

    test('handles price_per_seat as string', () {
      final json = {...sampleJson(), 'price_per_seat': '15.50'};
      final trip = TripModel.fromJson(json);
      expect(trip.pricePerSeat, 15.50);
    });

    test('handles invalid departure_at gracefully', () {
      final json = {...sampleJson(), 'departure_at': 'invalid-date'};
      final trip = TripModel.fromJson(json);
      expect(trip.departureAt, isA<DateTime>()); // fallback to DateTime.now()
    });

    test('parses in_progress status', () {
      final json = {...sampleJson(), 'status': 'in_progress'};
      final trip = TripModel.fromJson(json);
      expect(trip.status, 'in_progress');
    });

    test('driver_id falls back to driver.id when missing', () {
      final json = {...sampleJson()};
      json.remove('driver_id');
      final trip = TripModel.fromJson(json);
      expect(trip.driverId, 2); // from driver.id
    });
  });
}
