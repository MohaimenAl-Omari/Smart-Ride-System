import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user-model.dart';

class SessionService {
  static const String _kUserKey = 'smart_ride.session.user';
  static Future<void> save(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKey, jsonEncode(user.toJson()));
  }
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

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserKey);
  }

  static Future<bool> hasSession() async => (await load()) != null;
}
