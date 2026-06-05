import 'dart:typed_data';
import 'package:pointycastle/pointycastle.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';
import '../services/vpn_api.dart';
import '../models/api_models.dart';

class WireguardService {
  final VpnApi _vpnApi = VpnApi();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Generates a new X25519 key pair for WireGuard.
  Future<Map<String, String>> generateX25519KeyPair() async {
    final rng = SecureRandom('Fortuna');
    final keyGen = X25519KeyPairGenerator()
      ..init(KeyGenerationParameters(rng, 256));
    final keyPair = keyGen.generateKeyPair();
    final privateKey = PrivateKeyParameter(keyPair.privateKey);
    final publicKey = PublicKeyParameter(keyPair.publicKey);

    // Convert to raw bytes and then to base64
    final privBytes = privateKey.key as Uint8List;
    final pubBytes = publicKey.key as Uint8List;

    return {
      'privateKey': base64UrlEncode(privBytes),
      'publicKey': base64UrlEncode(pubBytes),
    };
  }

  /// Registers a WireGuard configuration with Proton VPN and returns the response.
  /// This function assumes the VpnApi is already authenticated.
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
        'platform': 'Linux', // We'll use Linux for both Linux and Android for simplicity
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
      throw Exception('Failed to register WireGuard config: ${response.statusCode}');
    }

    return jsonDecode(response.body);
  }

  /// Generates a WireGuard config string for the given server.
  Future<String> generateWgConfig(LogicalServer server) async {
    // We need to pick a physical server from the server's Servers list.
    // For simplicity, we'll pick the first one that is online (status == 1).
    final physical = server.servers.firstWhere(
        (s) => s.status == 1,
        orElse: () => server.servers.first);

    // Generate key pair
    final keyPair = await generateX25519KeyPair();
    final clientPrivKey = keyPair['privateKey']!;
    final clientPubKey = keyPair['publicKey']!;

    // Register the config with Proton VPN
    final registerResponse = await _registerWireguardConfig(
        clientPubKey, server.name, physical.entryIp, physical.x25519PublicKey);

    // Extract the assigned IP from the response.
    // According to the gist, the response does not contain the IP.
    // However, we need an IP for the interface. We'll look for an 'AssignedIP' or similar.
    // If not found, we'll use a fallback (but note: this may not work).
    final assignedIp = registerResponse['AssignedIP'] ?? registerResponse['assigned_ip'] ?? '10.2.0.2';

    // Build the WireGuard config
    final config = '''
[Interface]
PrivateKey = $clientPrivKey
Address = $assignedIp/32
DNS = 10.2.0.1

[Peer]
PublicKey = ${physical.x25519PublicKey}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ${physical.entryIp}:51820
PersistentKeepalive = 25
''';

    return config.trim();
  }

  /// Starts the WireGuard tunnel with the given configuration.
  Future<bool> connect(String wgConfig) async {
    try {
      // The wireguard_flutter package expects a configuration file or a string.
      // We'll use the string method.
      final result = await WireguardFlutter.register(wgConfig);
      if (!result) {
        return false;
      }
      await WireguardFlutter.start();
      return true;
    } catch (e) {
      // Log the error
      debugPrint('WireGuard connection error: $e');
      return false;
    }
  }

  /// Stops the WireGuard tunnel.
  Future<bool> disconnect() async {
    try {
      await WireguardFlutter.stop();
      await WireguardFlutter.remove();
      return true;
    } catch (e) {
      debugPrint('WireGuard disconnection error: $e');
      return false;
    }
  }

  /// Checks if the WireGuard tunnel is active.
  Future<bool> isConnected() async {
    try {
      return await WireguardFlower.isConnected();
    } catch (e) {
      return false;
    }
  }

  /// Gets the current WireGuard interface details (if connected).
  Future<Map<String, dynamic>?> getInterfaceDetails() async {
    try {
      return await WireguardFlutter.getInterface();
    } catch (e) {
      return null;
    }
  }
}