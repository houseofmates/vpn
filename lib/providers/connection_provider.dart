import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/wireguard_service.dart';
import '../models/api_models.dart';

class ConnectionProvider extends ChangeNotifier {
  final WireguardService _wireguardService = WireguardService();
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentServer;
  int _connectedSeconds = 0;
  Timer? _timer;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get currentServer => _currentServer;
  int get connectedSeconds => _connectedSeconds;

  Future<void> connectToServer(LogicalServer server) async {
    _isConnecting = true;
    notifyListeners();
    try {
      final config = await _wireguardService.generateWgConfig(server);
      final ok = await _wireguardService.connect(config);
      if (ok) {
        _isConnected = true;
        _currentServer = server.name;
        _connectedSeconds = 0;
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          _connectedSeconds++;
          notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('Connection error: $e');
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _wireguardService.disconnect();
    _isConnected = false;
    _currentServer = null;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
