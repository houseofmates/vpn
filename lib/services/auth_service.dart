import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'proton_srp.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _baseUrl = 'https://vpn-api.proton.me';

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Accept': 'application/vnd.protonmail.v1+json',
        'x-pm-appversion': 'web-vpn-settings@5.0.2.0',
        'User-Agent': 'ProtonVPN/1.0',
      };

  Future<User?> login(String username, String password, [String? totp]) async {
    try {
      return await _srpLogin(username, password, totp);
    } catch (e) {
      debugPrint('AuthService.login error: $e');
      rethrow;
    }
  }

  Future<User?> _srpLogin(
      String username, String password, [String? totp]) async {
    // Step 1: Get SRP parameters from /auth/v4/info
    final infoUrl = Uri.parse('$_baseUrl/auth/info');
    final infoResponse = await http.post(
      infoUrl,
      headers: _headers(),
      body: jsonEncode({'Username': username}),
    );

    if (infoResponse.statusCode != 200) {
      throw Exception(
          'Failed to get SRP info: ${infoResponse.statusCode} - ${infoResponse.body}');
    }

    final infoData = jsonDecode(infoResponse.body);
    if (infoData['Code'] != 1000) {
      throw Exception(
          'SRP info error: ${infoData['Code']} - ${infoData['Error']}');
    }

    final modulus = infoData['Modulus'] as String;
    final serverEphemeral = infoData['ServerEphemeral'] as String;
    final salt = infoData['Salt'] as String;
    final version = infoData['Version'] as int;
    final srpSession = infoData['SRPSession'] as String;

    // Step 2: Compute SRP proof
    final proof = ProtonSRP.computeProof(
      password: password,
      modulusArmored: modulus,
      serverEphemeralB64: serverEphemeral,
      saltB64: salt,
      version: version,
    );

    // Step 3: Send SRP proof to /auth/v4
    final authUrl = Uri.parse('$_baseUrl/auth');
    final authBody = {
      'ClientEphemeral': proof['clientEphemeral'],
      'ClientProof': proof['clientProof'],
      'SRPSession': srpSession,
    };

    final authResponse = await http.post(
      authUrl,
      headers: _headers(),
      body: jsonEncode(authBody),
    );

    if (authResponse.statusCode == 200) {
      final data = jsonDecode(authResponse.body);
      final user = User.fromJson(data);
      await _storage.write(key: 'accessToken', value: user.AccessToken);
      await _storage.write(key: 'refreshToken', value: user.refreshToken);
      await _storage.write(key: 'uid', value: user.uid.toString());
      return user;
    }

    throw Exception(
        'Failed to login: ${authResponse.statusCode} - ${authResponse.body}');
  }

  Future<User?> refreshToken() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    if (refreshToken == null) return null;

    final url = Uri.parse('$_baseUrl/auth/v4');
    final body = {
      'grant_type': 'refresh_token',
      'client_id': 'protonvpn',
      'client_secret': '',
      'refresh_token': refreshToken,
    };

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = User.fromJson(data);
      await _storage.write(key: 'accessToken', value: user.AccessToken);
      await _storage.write(key: 'refreshToken', value: user.refreshToken);
      return user;
    }

    return null;
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'accessToken');
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
