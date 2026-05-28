import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/vpn_api.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final VpnApi _vpnApi = VpnApi();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> login(String username, String password, [String? totp]) async {
    _setLoading(true);
    _setError(null);
    try {
      // First, login via auth service to get the access token
      final user = await _authService.login(username, password, totp);
      _user = user;
      // Then, initialize the VPN API with the session (if needed)
      await _vpnApi.init(); // This will load stored session or we can pass the tokens
      // For now, we assume the VpnApi uses the same secure storage
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshToken() async {
    _setLoading(true);
    try {
      final user = await _authService.refreshToken();
      if (user != null) {
        _user = user;
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    await _vpnApi.logout();
    _user = null;
    notifyListeners();
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