import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  final String _baseUrl = 'https://account.protonvpn.com';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<User?> login(String username, String password, [String? totp]) async {
    final url = Uri.parse('$_baseUrl/api/auth/v4');
    final body = {
      'username': username,
      'password': password,
      'grant_type': 'password',
      'client_id': 'protonvpn',
      'client_secret': '',
      'scope': '',
    };
    if (totp != null && totp.isNotEmpty) {
      body['totp'] = totp;
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = User.fromJson(data);
      await _storage.write(key: 'accessToken', value: user.accessToken);
      await _storage.write(key: 'refreshToken', value: user.refreshToken);
      await _storage.write(key: 'uid', value: user.uid.toString());
      return user;
    } else {
      throw Exception('Failed to login: ${response.statusCode}');
    }
  }

  Future<User?> refreshToken() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    if (refreshToken == null) return null;

    final url = Uri.parse('$_baseUrl/api/auth/v4');
    final body = {
      'grant_type': 'refresh_token',
      'client_id': 'protonvpn',
      'client_secret': '',
      'refresh_token': refreshToken,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = User.fromJson(data);
      await _storage.write(key: 'accessToken', value: user.accessToken);
      await _storage.write(key: 'refreshToken', value: user.refreshToken);
      return user;
    } else {
      return null;
    }
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'accessToken');
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}