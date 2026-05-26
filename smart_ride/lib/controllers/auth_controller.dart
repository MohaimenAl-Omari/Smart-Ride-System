import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constant.dart';
import '../core/session.dart';
import '../models/user-model.dart';

class AuthResult {
  final UserModel? user;
  final String? error;
  AuthResult({this.user, this.error});
  bool get success => user != null;
}

class AuthController {
  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? city,
  }) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
        if (city != null && city.isNotEmpty) 'city': city,
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      final token = (data['token'] ?? '').toString();
      final user = UserModel.fromJson(data['user'], token);
      await SessionService.save(user);
      return AuthResult(user: user);
    }
    return AuthResult(error: data['message']?.toString() ?? 'Registration failed');
  }

  Future<bool> uploadCertificates({
    required int userId,
    required File license,
    required File nonConviction,
    required File medical,
  }) async {
    final url = Uri.parse('$baseUrl/upload-certificates');
    final request = http.MultipartRequest('POST', url);
    request.headers['Accept'] = 'application/json';
    request.fields['user_id'] = userId.toString();
    request.files.add(await http.MultipartFile.fromPath('license', license.path));
    request.files
        .add(await http.MultipartFile.fromPath('non_conviction', nonConviction.path));
    request.files.add(await http.MultipartFile.fromPath('medical', medical.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body);
    return response.statusCode == 200 && data['status'] == true;
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {'email': email, 'password': password},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      final token = (data['token'] ?? '').toString();
      final user = UserModel.fromJson(data['user'], token);
      await SessionService.save(user);
      return AuthResult(user: user);
    }
    return AuthResult(error: data['message']?.toString() ?? 'Login failed');
  }

  Future<AuthResult> updateProfile({
    required UserModel current,
    String? name,
    String? email,
    String? phone,
    String? city,
    String? password,
    String? currentPassword,
    String? imagePath,
  }) async {
    final url = Uri.parse('$baseUrl/profile');
    final request = http.MultipartRequest('POST', url);
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer ${current.token}';

    if (name != null && name.isNotEmpty) request.fields['name'] = name;
    if (email != null && email.isNotEmpty) request.fields['email'] = email;
    if (phone != null && phone.isNotEmpty) request.fields['phone'] = phone;
    if (city != null && city.isNotEmpty) request.fields['city'] = city;
    if (password != null && password.isNotEmpty) {
      request.fields['password'] = password;
      request.fields['current_password'] = currentPassword ?? '';
    }
    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('profile_image', imagePath),
      );
    }

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final user = UserModel.fromJson(data['user'], current.token);
        await SessionService.save(user);
        return AuthResult(user: user);
      }
      return AuthResult(
          error: data['message']?.toString() ?? 'Update failed');
    } catch (e) {
      return AuthResult(error: 'Network error: $e');
    }
  }

  Future<UserModel?> getMe(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == true) {
        return UserModel.fromJson(data['user'], token);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> logout(String token) async {
    final url = Uri.parse('$baseUrl/logout');
    bool ok = false;
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      ok = response.statusCode == 200;
    } catch (_) {
      ok = false;
    }
    await SessionService.clear();
    return ok;
  }
}
