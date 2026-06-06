import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'proton_srp.dart';
import 'human_verification_exception.dart';

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
    // Step 1: Get SRP parameters from /auth/info
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

    // Step 3: Send SRP proof to /auth
    return _submitAuth(username, proof['clientEphemeral']!, proof['clientProof']!, srpSession);
  }

  Future<User?> _submitAuth(
    String username,
    String clientEphemeral,
    String clientProof,
    String srpSession, [
    String? humanVerificationToken,
  ]) async {
    final authUrl = Uri.parse('$_baseUrl/auth');
    final authBody = {
      'Username': username,
      'ClientEphemeral': clientEphemeral,
      'ClientProof': clientProof,
      'SRPSession': srpSession,
    };

    final headers = _headers();
    if (humanVerificationToken != null && humanVerificationToken.isNotEmpty) {
      headers['x-pm-human-verification-token'] = humanVerificationToken;
      headers['x-pm-human-verification-method'] = 'captcha';
    }

    final authResponse = await http.post(
      authUrl,
      headers: headers,
      body: jsonEncode(authBody),
    );

    // Handle human verification (captcha) if needed
    if (authResponse.statusCode == 422) {
      final data = jsonDecode(authResponse.body);
      if (data['Code'] == 9001 && data['Details'] != null) {
        final details = data['Details'];
        throw HumanVerificationException(
          token: details['HumanVerificationToken'] ?? '',
          methods: List<String>.from(
              details['HumanVerificationMethods'] ?? ['captcha']),
          webUrl: details['WebUrl'] ?? '',
          expiresAt: details['ExpiresAt'] ?? 0,
        );
      }
    }

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

  Future<User?> loginWithHumanVerification(
    String username,
    String password,
    String humanVerificationToken,
  ) async {
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

    final proof = ProtonSRP.computeProof(
      password: password,
      modulusArmored: modulus,
      serverEphemeralB64: serverEphemeral,
      saltB64: salt,
      version: version,
    );

    return _submitAuth(
      username,
      proof['clientEphemeral']!,
      proof['clientProof']!,
      srpSession,
      humanVerificationToken,
    );
  }

  Future<User?> refreshToken() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    if (refreshToken == null) return null;

    final url = Uri.parse('$_baseUrl/auth/refresh');
    final body = {
      'ResponseType': 'token',
      'GrantType': 'refresh_token',
      'RefreshToken': refreshToken,
      'RedirectURI': 'http://protonmail.ch',
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
