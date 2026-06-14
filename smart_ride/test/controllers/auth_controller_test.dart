import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ride/controllers/auth_controller.dart';

// ── Helper ────────────────────────────────────────────────────────
MockClient _mockClient(Map<String, dynamic> body, {int status = 200}) {
  return MockClient((_) async => http.Response(jsonEncode(body), status));
}

Map<String, dynamic> _userPayload({String role = 'passenger'}) => {
      'id': 1,
      'name': 'Ali Hassan',
      'email': 'ali@example.com',
      'phone': '0790001111',
      'role': role,
      'city': 'Amman',
      'image': null,
      'image_url': null,
      'rating_average': 0,
      'ratings_count': 0,
      'is_active': true,
      'balance': '0.00',
    };

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ──────────────────────────────────────────────────────────────
  // login
  // ──────────────────────────────────────────────────────────────
  group('AuthController.login', () {
    test('returns UserModel on success', () async {
      final client = _mockClient({
        'status': true,
        'token': 'plain_token_abc',
        'user': _userPayload(),
      });

      final ctrl = AuthController(client: client);
      final result = await ctrl.login(email: 'ali@example.com', password: 'secret');

      expect(result.success, isTrue);
      expect(result.user!.email, 'ali@example.com');
      expect(result.user!.token, 'plain_token_abc');
    });

    test('returns error on invalid credentials (401)', () async {
      final client = _mockClient(
        {'status': false, 'message': 'Invalid credentials'},
        status: 401,
      );
      final ctrl = AuthController(client: client);
      final result = await ctrl.login(email: 'x@x.com', password: 'wrong');

      expect(result.success, isFalse);
      expect(result.error, 'Invalid credentials');
    });

    test('returns error when driver is pending (403)', () async {
      final client = _mockClient(
        {'status': false, 'message': 'Your driver account is pending admin approval'},
        status: 403,
      );
      final ctrl = AuthController(client: client);
      final result = await ctrl.login(email: 'd@d.com', password: 'pass');

      expect(result.success, isFalse);
      expect(result.error, contains('pending'));
    });
  });

  // ──────────────────────────────────────────────────────────────
  // register
  // ──────────────────────────────────────────────────────────────
  group('AuthController.register', () {
    test('returns UserModel on success for passenger', () async {
      final client = _mockClient({
        'status': true,
        'token': 'reg_token',
        'message': 'User registered successfully',
        'user': _userPayload(),
      });
      final ctrl = AuthController(client: client);
      final result = await ctrl.register(
        name: 'Ali Hassan',
        email: 'ali@example.com',
        phone: '0790001111',
        password: 'secret',
        role: 'passenger',
      );

      expect(result.success, isTrue);
      expect(result.user!.role, 'passenger');
    });

    test('returns empty token for pending driver registration', () async {
      final client = _mockClient({
        'status': true,
        'token': '',
        'message': 'Driver registered. Awaiting admin approval.',
        'user': _userPayload(role: 'driver'),
      });
      final ctrl = AuthController(client: client);
      final result = await ctrl.register(
        name: 'Sami',
        email: 'sami@example.com',
        phone: '0790002222',
        password: 'pass',
        role: 'driver',
      );

      expect(result.success, isTrue);
      expect(result.user!.token, '');
    });

    test('returns error on duplicate email (400)', () async {
      final client = _mockClient(
        {'status': false, 'message': 'The email has already been taken.'},
        status: 400,
      );
      final ctrl = AuthController(client: client);
      final result = await ctrl.register(
        name: 'X', email: 'dup@example.com', phone: '0790003333',
        password: 'pass', role: 'passenger',
      );

      expect(result.success, isFalse);
      expect(result.error, contains('email'));
    });
  });

  // ──────────────────────────────────────────────────────────────
  // getMe
  // ──────────────────────────────────────────────────────────────
  group('AuthController.getMe', () {
    test('returns UserModel when token is valid', () async {
      final client = _mockClient({
        'status': true,
        'user': _userPayload(),
      });
      final ctrl = AuthController(client: client);
      final user = await ctrl.getMe('valid_token');

      expect(user, isNotNull);
      expect(user!.name, 'Ali Hassan');
    });

    test('returns null when token is invalid (401)', () async {
      final client = _mockClient({'status': false, 'message': 'Unauthenticated.'}, status: 401);
      final ctrl = AuthController(client: client);
      final user = await ctrl.getMe('bad_token');

      expect(user, isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // logout
  // ──────────────────────────────────────────────────────────────
  group('AuthController.logout', () {
    test('returns true on success', () async {
      final client = _mockClient({'status': true, 'message': 'Logged out successfully'});
      final ctrl = AuthController(client: client);
      final ok = await ctrl.logout('valid_token');

      expect(ok, isTrue);
    });

    test('returns false when server errors', () async {
      final client = _mockClient({'status': false}, status: 500);
      final ctrl = AuthController(client: client);
      final ok = await ctrl.logout('token');

      expect(ok, isFalse);
    });
  });
}
