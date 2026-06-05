import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import '../services/vpn_api.dart';
import '../models/api_models.dart';

class WireguardService {
  final VpnApi _vpnApi = VpnApi();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Generates a new X25519 key pair (stub).
  Future<Map<String, String>> generateX25519KeyPair() async {
    // For now, return dummy keys so the app compiles.
    // Real key generation will use cryptography package.
    return {
      'privateKey': base64Encode(List.filled(32, 0)),
      'publicKey': base64Encode(List.filled(32, 0)),
    };
  }

  Future<Map<String, dynamic>> _registerWireguardConfig(
      String clientPublicKey, String serverName, String serverEntryIp,
      String serverPublicKey) async {
    final body = {
      'ClientPublicKey': clientPublicKey,
      'Mode': 'persistent',
      'DeviceName': 'vpn-$serverName',
      'Features': {
        'peerName': serverName,
        'peerIp': serverEntryIp,
        'peerPublicKey': serverPublicKey,
        'platform': 'Linux',
        'SafeMode': false,
        'SplitTCP': true,
        'PortForwarding': true,
        'RandomNAT': false,
        'NetShieldLevel': 0,
      }
    };

    final response = await _vpnApi.post('/api/vpn/v1/certificate',
        jsonBody: jsonEncode(body));

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to register WireGuard config: ${response.statusCode}');
    }

    return jsonDecode(response.body);
  }

  Future<String> generateWgConfig(LogicalServer server) async {
    // Stub – returns an empty config for now
    return '';
  }

  Future<bool> connect(String wgConfig) async {
    // Stub
    return true;
  }

  Future<bool> disconnect() async {
    return true;
  }

  Future<bool> isConnected() async {
    return false;
  }

  Future<Map<String, dynamic>?> getInterfaceDetails() async {
    return null;
  }
}
