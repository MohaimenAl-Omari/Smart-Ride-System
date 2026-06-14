import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ride/models/booking_model.dart';

void main() {
  Map<String, dynamic> sampleJson() => {
        'id': 5,
        'trip_id': 10,
        'passenger_id': 3,
        'pickup_stop': 'Irbid',
        'dropoff_stop': 'Amman',
        'seats': 2,
        'total_price': '20.00',
        'debt_carried': '0.00',
        'status': 'pending',
        'is_checked_in': false,
        'no_show': false,
        'location_area': 'Downtown',
        'location_street': 'King St',
        'location_building': '5A',
        'payment_method': 'cash',
        'passenger': {'name': 'Ali', 'phone': '0790001111'},
        'trip': {
          'origin': 'Irbid',
          'destination': 'Amman',
          'departure_at': '2026-07-01T08:00:00.000000Z',
          'car_model': 'Toyota',
          'car_plate': 'A-111',
          'driver': {'name': 'Sami', 'phone': '0790002222'},
        },
      };

  group('BookingModel.fromJson', () {
    test('parses all fields correctly', () {
      final b = BookingModel.fromJson(sampleJson());

      expect(b.id, 5);
      expect(b.tripId, 10);
      expect(b.passengerId, 3);
      expect(b.pickupStop, 'Irbid');
      expect(b.dropoffStop, 'Amman');
      expect(b.seats, 2);
      expect(b.totalPrice, 20.0);
      expect(b.debtCarried, 0.0);
      expect(b.status, 'pending');
      expect(b.isCheckedIn, isFalse);
      expect(b.noShow, isFalse);
      expect(b.paymentMethod, 'cash');
    });

    test('parses passenger info', () {
      final b = BookingModel.fromJson(sampleJson());
      expect(b.passengerName, 'Ali');
      expect(b.passengerPhone, '0790001111');
    });

    test('parses trip and driver info', () {
      final b = BookingModel.fromJson(sampleJson());
      expect(b.tripOrigin, 'Irbid');
      expect(b.tripDestination, 'Amman');
      expect(b.driverName, 'Sami');
      expect(b.carModel, 'Toyota');
      expect(b.carPlate, 'A-111');
    });

    test('parses tripDepartureAt as DateTime', () {
      final b = BookingModel.fromJson(sampleJson());
      expect(b.tripDepartureAt, isA<DateTime>());
      expect(b.tripDepartureAt!.year, 2026);
    });

    test('handles is_checked_in as integer 1', () {
      final json = {...sampleJson(), 'is_checked_in': 1};
      final b = BookingModel.fromJson(json);
      expect(b.isCheckedIn, isTrue);
    });

    test('handles no_show as integer 1', () {
      final json = {...sampleJson(), 'no_show': 1};
      final b = BookingModel.fromJson(json);
      expect(b.noShow, isTrue);
    });

    test('handles missing passenger gracefully', () {
      final json = {...sampleJson(), 'passenger': null};
      final b = BookingModel.fromJson(json);
      expect(b.passengerName, isNull);
      expect(b.passengerPhone, isNull);
    });

    test('handles missing trip gracefully', () {
      final json = {...sampleJson(), 'trip': null};
      final b = BookingModel.fromJson(json);
      expect(b.tripOrigin, isNull);
      expect(b.tripDestination, isNull);
      expect(b.driverName, isNull);
    });

    test('parses accepted status', () {
      final json = {...sampleJson(), 'status': 'accepted'};
      final b = BookingModel.fromJson(json);
      expect(b.status, 'accepted');
    });
  });

  group('BookingModel.locationSummary', () {
    test('returns combined location string', () {
      final b = BookingModel.fromJson(sampleJson());
      expect(b.locationSummary, contains('5A'));
      expect(b.locationSummary, contains('King St'));
      expect(b.locationSummary, contains('Downtown'));
    });

    test('returns null when no location fields set', () {
      final json = {
        ...sampleJson(),
        'location_area': null,
        'location_street': null,
        'location_building': null,
      };
      final b = BookingModel.fromJson(json);
      expect(b.locationSummary, isNull);
    });

    test('returns partial summary when only area is set', () {
      final json = {
        ...sampleJson(),
        'location_area': 'West Side',
        'location_street': null,
        'location_building': null,
      };
      final b = BookingModel.fromJson(json);
      expect(b.locationSummary, 'West Side');
    });
  });
}
