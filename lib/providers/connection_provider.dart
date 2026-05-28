import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/wireguard_service.dart';
import '../models/server.dart';

class ConnectionProvider with ChangeNotifier {
  final WireguardService _wireguardService = WireguardService();
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentServer;
  String? _connectionError;
  Timer? _connectionTimer;
  int _connectedSeconds = 0;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get currentServer => _currentServer;
  String? get connectionError => _connectionError;
  int get connectedSeconds => _connectedSeconds;

  Future<void> connectToServer(LogicalServer server) async {
    _setConnecting(true);
    _setError(null);
    try {
      final config = await _wireguardService.generateWgConfig(server);
      final success = await _wireguardService.connect(config);
      if (success) {
        _setConnected(true, server.name);
        _startConnectionTimer();
      } else {
        _setError('Failed to start WireGuard tunnel');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setConnecting(false);
    }
  }

  Future<void> disconnect() async {
    _stopConnectionTimer();
    await _wireguardService.disconnect();
    _setConnected(false, null);
  }

  void _setConnected(bool connected, String? serverName) {
    _isConnected = connected;
    _currentServer = serverName;
    if (!connected) {
      _connectedSeconds = 0;
    }
    notifyListeners();
  }

  void _setConnecting(bool connecting) {
    _isConnecting = connecting;
    notifyListeners();
  }

  void _setError(String? error) {
    _connectionError = error;
    notifyListeners();
  }

  void _startConnectionTimer() {
    _connectedSeconds = 0;
    _connectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _connectedSeconds++;
      notifyListeners();
    });
  }

  void _stopConnectionTimer() {
    _connectionTimer?.cancel();
    _connectionTimer = null;
  }

  // Optional: method to get current traffic stats (if needed)
}