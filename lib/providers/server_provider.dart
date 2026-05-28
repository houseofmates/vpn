import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/vpn_api.dart';
import '../models/api_models.dart';

class ServerProvider with ChangeNotifier {
  final VpnApi _vpnApi = VpnApi();
  List<LogicalServer> _servers = [];
  bool _isLoading = false;
  String? _error;

  List<LogicalServer> get servers => _servers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadServers() async {
    _setLoading(true);
    _setError(null);
    try {
      // Ensure the VPN API is initialized (loads session from storage)
      await _vpnApi.init();
      final response = await _vpnApi.get('/api/vpn/logicals');
      if (response.statusCode == 200) {
        final data = logicalServersResponseFromJson(response.body);
        // Filter for free servers (Tier == 0)
        _servers = data.logicalServers
            .where((server) => server.tier == 0)
            .toList();
        notifyListeners();
      } else {
        _setError('Failed to load servers: ${response.statusCode}');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}