import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_ride/controllers/booking_controller.dart';

MockClient _mockClient(Map<String, dynamic> body, {int status = 200}) =>
    MockClient((_) async => http.Response(jsonEncode(body), status));

Map<String, dynamic> _bookingJson({String status = 'pending'}) => {
      'id': 5,
      'trip_id': 10,
      'passenger_id': 3,
      'pickup_stop': 'Irbid',
      'dropoff_stop': 'Amman',
      'seats': 1,
      'total_price': '10.00',
      'debt_carried': '0.00',
      'status': status,
      'is_checked_in': false,
      'no_show': false,
      'payment_method': null,
      'passenger': {'name': 'Ali', 'phone': '079'},
      'trip': {
        'origin': 'Irbid',
        'destination': 'Amman',
        'departure_at': '2026-07-01T08:00:00.000000Z',
        'car_model': 'Toyota',
        'car_plate': 'A-111',
        'driver': {'name': 'Sami', 'phone': '079'},
      },
    };

void main() {
  // ──────────────────────────────────────────────────────────────
  // create
  // ──────────────────────────────────────────────────────────────
  group('BookingController.create', () {
    test('returns success on 200', () async {
      final client = _mockClient({
        'status': true,
        'message': 'Booking request sent. Waiting for driver to accept.',
        'booking': _bookingJson(),
      });
      final ctrl = BookingController(client: client);
      final result = await ctrl.create(token: 'tok', tripId: 10, seats: 1);

      expect(result.success, isTrue);
      expect(result.message, contains('Waiting'));
    });

    test('returns failure on passenger self-booking (403)', () async {
      final client = _mockClient(
        {'status': false, 'message': 'You cannot book your own trip.'},
        status: 403,
      );
      final ctrl = BookingController(client: client);
      final result = await ctrl.create(token: 'tok', tripId: 10, seats: 1);

      expect(result.success, isFalse);
      expect(result.message, contains('own trip'));
    });

    test('returns failure on duplicate booking (400)', () async {
      final client = _mockClient(
        {'status': false, 'message': 'You already have an active booking on this trip.'},
        status: 400,
      );
      final ctrl = BookingController(client: client);
      final result = await ctrl.create(token: 'tok', tripId: 10, seats: 1);

      expect(result.success, isFalse);
    });

    test('returns failure when no seats available (400)', () async {
      final client = _mockClient(
        {'status': false, 'message': 'Not enough seats available.'},
        status: 400,
      );
      final ctrl = BookingController(client: client);
      final result = await ctrl.create(token: 'tok', tripId: 10, seats: 5);

      expect(result.success, isFalse);
      expect(result.message, contains('seats'));
    });
  });

  // ──────────────────────────────────────────────────────────────
  // myBookings
  // ──────────────────────────────────────────────────────────────
  group('BookingController.myBookings', () {
    test('returns list of bookings', () async {
      final client = _mockClient({'status': true, 'bookings': [_bookingJson()]});
      final ctrl = BookingController(client: client);
      final bookings = await ctrl.myBookings('tok');

      expect(bookings.length, 1);
      expect(bookings.first.status, 'pending');
    });

    test('returns empty list on auth failure', () async {
      final client = _mockClient({'status': false}, status: 401);
      final ctrl = BookingController(client: client);
      final bookings = await ctrl.myBookings('bad');

      expect(bookings, isEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // driverBookings
  // ──────────────────────────────────────────────────────────────
  group('BookingController.driverBookings', () {
    test('returns bookings for driver', () async {
      final client = _mockClient({'status': true, 'bookings': [_bookingJson(), _bookingJson()]});
      final ctrl = BookingController(client: client);
      final bookings = await ctrl.driverBookings('tok');

      expect(bookings.length, 2);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // accept
  // ──────────────────────────────────────────────────────────────
  group('BookingController.accept', () {
    test('returns true on success', () async {
      final client = _mockClient({'status': true, 'message': 'Booking accepted.'});
      final ctrl = BookingController(client: client);
      expect(await ctrl.accept('tok', 5), isTrue);
    });

    test('returns false when forbidden (403)', () async {
      final client = _mockClient({'status': false}, status: 403);
      final ctrl = BookingController(client: client);
      expect(await ctrl.accept('tok', 5), isFalse);
    });

    test('returns false when booking already accepted (400)', () async {
      final client = _mockClient(
        {'status': false, 'message': 'Only pending bookings can be accepted.'},
        status: 400,
      );
      final ctrl = BookingController(client: client);
      expect(await ctrl.accept('tok', 5), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // reject
  // ──────────────────────────────────────────────────────────────
  group('BookingController.reject', () {
    test('returns true on success', () async {
      final client = _mockClient({'status': true, 'message': 'Booking rejected.'});
      final ctrl = BookingController(client: client);
      expect(await ctrl.reject('tok', 5), isTrue);
    });

    test('returns false when not pending (400)', () async {
      final client = _mockClient({'status': false}, status: 400);
      final ctrl = BookingController(client: client);
      expect(await ctrl.reject('tok', 5), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // cancel
  // ──────────────────────────────────────────────────────────────
  group('BookingController.cancel', () {
    test('returns true on success', () async {
      final client = _mockClient({'status': true, 'message': 'Booking cancelled.'});
      final ctrl = BookingController(client: client);
      expect(await ctrl.cancel('tok', 5), isTrue);
    });

    test('returns false when forbidden (403)', () async {
      final client = _mockClient({'status': false}, status: 403);
      final ctrl = BookingController(client: client);
      expect(await ctrl.cancel('tok', 5), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // checkIn (passenger)
  // ──────────────────────────────────────────────────────────────
  group('BookingController.checkIn', () {
    test('returns success result on 200', () async {
      final client = _mockClient({'status': true, 'message': 'Checked in successfully.'});
      final ctrl = BookingController(client: client);
      final result = await ctrl.checkIn('tok', 5);

      expect(result.success, isTrue);
      expect(result.message, contains('Checked in'));
    });

    test('returns failure when check-in window has not opened (400)', () async {
      final client = _mockClient(
        {'status': false, 'message': 'Check-in opens 60 minutes before departure.'},
        status: 400,
      );
      final ctrl = BookingController(client: client);
      final result = await ctrl.checkIn('tok', 5);

      expect(result.success, isFalse);
      expect(result.message, contains('60 minutes'));
    });

    test('returns failure when already checked in (400)', () async {
      final client = _mockClient(
        {'status': false, 'message': 'You already checked in.'},
        status: 400,
      );
      final ctrl = BookingController(client: client);
      final result = await ctrl.checkIn('tok', 5);

      expect(result.success, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // driverCheckIn
  // ──────────────────────────────────────────────────────────────
  group('BookingController.driverCheckIn', () {
    test('returns success on 200', () async {
      final client = _mockClient({'status': true, 'message': 'Passenger checked in.'});
      final ctrl = BookingController(client: client);
      final result = await ctrl.driverCheckIn('tok', 5);

      expect(result.success, isTrue);
    });

    test('returns failure when forbidden (403)', () async {
      final client = _mockClient({'status': false}, status: 403);
      final ctrl = BookingController(client: client);
      final result = await ctrl.driverCheckIn('tok', 5);

      expect(result.success, isFalse);
    });
  });
}
