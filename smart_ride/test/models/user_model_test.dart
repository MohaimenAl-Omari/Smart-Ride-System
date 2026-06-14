import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ride/models/user-model.dart';

void main() {
  // ── Sample JSON that mirrors what the Laravel API returns ──────
  Map<String, dynamic> sampleJson() => {
        'id': 1,
        'name': 'Ali Hassan',
        'email': 'ali@example.com',
        'phone': '0790001111',
        'role': 'passenger',
        'city': 'Amman',
        'image': null,
        'image_url': null,
        'rating_average': 0,
        'ratings_count': 0,
        'is_active': true,
        'balance': '10.50',
      };

  group('UserModel.fromJson', () {
    test('parses all fields correctly', () {
      final user = UserModel.fromJson(sampleJson(), 'tok123');

      expect(user.id, 1);
      expect(user.name, 'Ali Hassan');
      expect(user.email, 'ali@example.com');
      expect(user.phone, '0790001111');
      expect(user.role, 'passenger');
      expect(user.city, 'Amman');
      expect(user.token, 'tok123');
      expect(user.isActive, isTrue);
      expect(user.balance, 10.50);
    });

    test('defaults missing optional fields to safe values', () {
      final json = {
        'id': 2,
        'name': '',
        'email': '',
        'phone': '',
        'role': 'passenger',
      };
      final user = UserModel.fromJson(json, '');

      expect(user.city, isNull);
      expect(user.image, isNull);
      expect(user.ratingAverage, 0.0);
      expect(user.ratingsCount, 0);
      expect(user.balance, 0.0);
    });

    test('handles is_active as integer 1', () {
      final json = {...sampleJson(), 'is_active': 1};
      final user = UserModel.fromJson(json, 'tok');
      expect(user.isActive, isTrue);
    });

    test('handles is_active as integer 0', () {
      final json = {...sampleJson(), 'is_active': 0};
      final user = UserModel.fromJson(json, 'tok');
      expect(user.isActive, isFalse);
    });

    test('parses balance from string', () {
      final json = {...sampleJson(), 'balance': '25.75'};
      final user = UserModel.fromJson(json, 'tok');
      expect(user.balance, 25.75);
    });

    test('parses balance from number', () {
      final json = {...sampleJson(), 'balance': 5.0};
      final user = UserModel.fromJson(json, 'tok');
      expect(user.balance, 5.0);
    });

    test('handles null balance', () {
      final json = {...sampleJson(), 'balance': null};
      final user = UserModel.fromJson(json, 'tok');
      expect(user.balance, 0.0);
    });

    test('driver role is preserved', () {
      final json = {...sampleJson(), 'role': 'driver', 'rating_average': 4.5, 'ratings_count': 12};
      final user = UserModel.fromJson(json, 'tok');
      expect(user.role, 'driver');
      expect(user.ratingAverage, 4.5);
      expect(user.ratingsCount, 12);
    });
  });

  group('UserModel.fromStored', () {
    test('parses id stored as string', () {
      final json = {
        ...sampleJson(),
        'id': '42',
        'token': 'stored_token',
        'is_active': true,
      };
      final user = UserModel.fromStored(json);
      expect(user.id, 42);
      expect(user.token, 'stored_token');
    });

    test('handles is_active stored as bool true', () {
      final json = {...sampleJson(), 'id': 1, 'token': 'tok', 'is_active': true};
      final user = UserModel.fromStored(json);
      expect(user.isActive, isTrue);
    });

    test('handles is_active stored as string "1"', () {
      final json = {...sampleJson(), 'id': 1, 'token': 'tok', 'is_active': '1'};
      final user = UserModel.fromStored(json);
      expect(user.isActive, isTrue);
    });
  });

  group('UserModel.copyWith', () {
    test('copies with updated name', () {
      final original = UserModel.fromJson(sampleJson(), 'tok');
      final updated = original.copyWith(name: 'Updated Name');
      expect(updated.name, 'Updated Name');
      expect(updated.email, original.email);
      expect(updated.id, original.id);
    });

    test('copies with updated balance', () {
      final original = UserModel.fromJson(sampleJson(), 'tok');
      final updated = original.copyWith(balance: -20.0);
      expect(updated.balance, -20.0);
    });

    test('leaves unchanged fields intact', () {
      final original = UserModel.fromJson(sampleJson(), 'tok');
      final updated = original.copyWith(city: 'Zarqa');
      expect(updated.role, original.role);
      expect(updated.phone, original.phone);
    });
  });

  group('UserModel.toJson', () {
    test('round-trips correctly via toJson', () {
      final user = UserModel.fromJson(sampleJson(), 'tok');
      final json = user.toJson();
      expect(json['name'], user.name);
      expect(json['email'], user.email);
      expect(json['role'], user.role);
      expect(json['balance'], user.balance);
    });
  });
}
