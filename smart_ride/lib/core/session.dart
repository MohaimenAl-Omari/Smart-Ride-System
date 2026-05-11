import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user-model.dart';

/// Persists the signed-in user across app restarts.
///
/// We store the full [UserModel] (including the bearer token) as a JSON
/// string in [SharedPreferences] under [_kUserKey]. This is sufficient
/// for a student / prototype app; in a production build we'd move the
/// token into `flutter_secure_storage` (encrypted keystore / keychain).
class SessionService {
  static const String _kUserKey = 'smart_ride.session.user';

  /// Save the user after a successful login or registration.
  static Future<void> save(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKey, jsonEncode(user.toJson()));
  }

  /// Load the previously saved user, or `null` if there isn't one or
  /// the saved record is corrupt.
  static Future<UserModel?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kUserKey);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final user = UserModel.fromStored(map);
      if (user.token.isEmpty) return null;
      return user;
    } catch (_) {
      return null;
    }
  }

  /// Clear the saved session — call on logout or when the server
  /// reports the token is no longer valid.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserKey);
  }

  /// Convenience helper used by app start.
  static Future<bool> hasSession() async => (await load()) != null;
}
