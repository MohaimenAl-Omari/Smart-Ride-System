import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_ride/controllers/trip_controller.dart';

// ── Helper ────────────────────────────────────────────────────────
MockClient _mockClient(Map<String, dynamic> body, {int status = 200}) =>
    MockClient((_) async => http.Response(jsonEncode(body), status));

Map<String, dynamic> _tripJson({String status = 'scheduled'}) => {
      'id': 10,
      'driver_id': 2,
      'origin': 'Irbid',
      'destination': 'Amman',
      'departure_at': '2026-07-01T08:00:00.000000Z',
      'seats_total': 4,
      'seats_available': 4,
      'min_passengers': 1,
      'price_per_seat': '10.00',
      'car_model': 'Toyota',
      'car_plate': 'A-111',
      'notes': null,
      'status': status,
      'driver': {
        'id': 2,
        'name': 'Sami',
        'phone': '0790002222',
        'rating_average': 4.5,
        'ratings_count': 5,
      },
      'stops': [],
      'bookings': [],
    };

void main() {
  // ──────────────────────────────────────────────────────────────
  // search
  // ──────────────────────────────────────────────────────────────
  group('TripController.search', () {
    test('returns list of trips on success', () async {
      final client = _mockClient({'status': true, 'trips': [_tripJson()]});
      final ctrl = TripController(client: client);
      final trips = await ctrl.search(token: 'tok', from: 'Irbid', to: 'Amman');

      expect(trips.length, 1);
      expect(trips.first.origin, 'Irbid');
      expect(trips.first.destination, 'Amman');
    });

    test('returns empty list when no trips match', () async {
      final client = _mockClient({'status': true, 'trips': []});
      final ctrl = TripController(client: client);
      final trips = await ctrl.search(token: 'tok', from: 'Aqaba', to: 'Mafraq');

      expect(trips, isEmpty);
    });

    test('returns empty list on error response', () async {
      final client = _mockClient({'status': false}, status: 401);
      final ctrl = TripController(client: client);
      final trips = await ctrl.search(token: 'bad');

      expect(trips, isEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // show
  // ──────────────────────────────────────────────────────────────
  group('TripController.show', () {
    test('returns TripModel on success', () async {
      final client = _mockClient({'status': true, 'trip': _tripJson()});
      final ctrl = TripController(client: client);
      final trip = await ctrl.show(token: 'tok', id: 10);

      expect(trip, isNotNull);
      expect(trip!.id, 10);
      expect(trip.status, 'scheduled');
    });

    test('returns null when trip not found (404)', () async {
      final client = _mockClient({'message': 'Not Found'}, status: 404);
      final ctrl = TripController(client: client);
      final trip = await ctrl.show(token: 'tok', id: 9999);

      expect(trip, isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // driverTrips
  // ──────────────────────────────────────────────────────────────
  group('TripController.driverTrips', () {
    test('returns driver trips list', () async {
      final client = _mockClient({'status': true, 'trips': [_tripJson(), _tripJson()]});
      final ctrl = TripController(client: client);
      final trips = await ctrl.driverTrips('tok');

      expect(trips.length, 2);
    });

    test('returns empty list on failure', () async {
      final client = _mockClient({'status': false}, status: 403);
      final ctrl = TripController(client: client);
      final trips = await ctrl.driverTrips('passenger_tok');

      expect(trips, isEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // create
  // ──────────────────────────────────────────────────────────────
  group('TripController.create', () {
    test('returns TripModel on success', () async {
      final client = _mockClient({'status': true, 'trip': _tripJson()});
      final ctrl = TripController(client: client);
      final trip = await ctrl.create(
        token: 'tok',
        origin: 'Irbid',
        destination: 'Amman',
        departureAt: DateTime.now().add(const Duration(days: 1)),
        seatsTotal: 4,
        pricePerSeat: 10.0,
        segmentPrices: [10.0],
      );

      expect(trip, isNotNull);
      expect(trip!.origin, 'Irbid');
    });

    test('returns null on validation error (400)', () async {
      final client = _mockClient(
        {'status': false, 'message': 'The departure at must be a date after now.'},
        status: 400,
      );
      final ctrl = TripController(client: client);
      final trip = await ctrl.create(
        token: 'tok',
        origin: 'Irbid',
        destination: 'Amman',
        departureAt: DateTime.now().subtract(const Duration(hours: 1)),
        seatsTotal: 4,
        pricePerSeat: 10.0,
      );

      expect(trip, isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // cancel
  // ──────────────────────────────────────────────────────────────
  group('TripController.cancel', () {
    test('returns true on success', () async {
      final client = _mockClient({'status': true, 'message': 'Trip cancelled.'});
      final ctrl = TripController(client: client);
      final ok = await ctrl.cancel('tok', 10);

      expect(ok, isTrue);
    });

    test('returns false when forbidden (403)', () async {
      final client = _mockClient({'status': false}, status: 403);
      final ctrl = TripController(client: client);
      final ok = await ctrl.cancel('tok', 10);

      expect(ok, isFalse);
    });

    test('returns false when trip not found (404)', () async {
      final client = _mockClient({'message': 'Not Found'}, status: 404);
      final ctrl = TripController(client: client);
      final ok = await ctrl.cancel('tok', 9999);

      expect(ok, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // start
  // ──────────────────────────────────────────────────────────────
  group('TripController.start', () {
    test('returns true on success', () async {
      final client = _mockClient({
        'status': true,
        'message': 'Trip started.',
        'checked_in_count': 2,
        'no_show_count': 1,
      });
      final ctrl = TripController(client: client);
      final ok = await ctrl.start('tok', 10);

      expect(ok, isTrue);
    });

    test('returns false when already started (400)', () async {
      final client = _mockClient(
        {'status': false, 'message': 'Only scheduled trips can be started.'},
        status: 400,
      );
      final ctrl = TripController(client: client);
      final ok = await ctrl.start('tok', 10);

      expect(ok, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // complete
  // ──────────────────────────────────────────────────────────────
  group('TripController.complete', () {
    test('returns true on success', () async {
      final client = _mockClient({'status': true, 'message': 'Trip completed.'});
      final ctrl = TripController(client: client);
      final ok = await ctrl.complete('tok', 10);

      expect(ok, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // driverHistory
  // ──────────────────────────────────────────────────────────────
  group('TripController.driverHistory', () {
    test('returns list of history trips', () async {
      final historyJson = {
        'id': 1,
        'origin': 'Irbid',
        'destination': 'Amman',
        'departure_at': '2026-06-01T08:00:00.000000Z',
        'seats_total': 4,
        'price_per_seat': '10.00',
        'status': 'completed',
        'passengers_count': '3',
        'total_earnings': '30.00',
        'stops': [],
      };
      final client = _mockClient({'status': true, 'trips': [historyJson]});
      final ctrl = TripController(client: client);
      final history = await ctrl.driverHistory('tok');

      expect(history.length, 1);
      expect(history.first.status, 'completed');
      expect(history.first.passengersCount, 3);
      expect(history.first.totalEarnings, 30.0);
    });

    test('returns empty list on failure', () async {
      final client = _mockClient({'status': false}, status: 403);
      final ctrl = TripController(client: client);
      final history = await ctrl.driverHistory('tok');

      expect(history, isEmpty);
    });
  });
}
