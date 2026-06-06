import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VpnApi {
  static final VpnApi _instance = VpnApi._internal();
  factory VpnApi() => _instance;
  VpnApi._internal();

  final String _baseUrl = 'https://account.protonvpn.com';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late http.Client _client;
  String? _uid;
  Map<String, String> _cookies = {};

  Future<void> init() async {
    _client = http.Client();
    // Load stored session if any
    final uid = await _storage.read(key: 'vpn_uid');
    final cookiesStr = await _storage.read(key: 'vpn_cookies');
    if (uid != null && cookiesStr != null) {
      _uid = uid;
      _cookies = Map<String, String>.from(jsonDecode(cookiesStr));
    }
  }

  Future<bool> login(String username, String password, [String? totp]) async {
    throw Exception('Use AuthService.login() for SRP-based authentication');
  }

  Future<Map<String, String>> _getVpnHeaders() async {
    // Ensure we have uid and cookies
    if (_uid == null) {
      await init();
    }
    final headers = <String, String>{
      'x-pm-uid': _uid!,
      'x-pm-appversion': 'web-vpn-settings@5.0.2.0', // This might need to be updated
      'Accept': 'application/vnd.protonmail.v1+json',
    };
    // Add cookies
    if (_cookies.isNotEmpty) {
      final cookieString = _cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');
      headers['Cookie'] = cookieString;
    }
    return headers;
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _getVpnHeaders();
    return await _client.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
    );
  }

  Future<http.Response> post(String endpoint,
      {Map<String, dynamic>? body, String? jsonBody}) async {
    final headers = await _getVpnHeaders();
    headers['Content-Type'] = 'application/json';
    final bodyBytes = jsonBody != null
        ? utf8.encode(jsonBody)
        : body != null
            ? utf8.encode(jsonEncode(body))
            : null;
    return await _client.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: bodyBytes,
    );
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _uid = null;
    _cookies.clear();
    if (_client != null) {
      _client.close();
    }
  }
}