import 'package:flutter/foundation.dart';
import '../models/api_models.dart';

class ServerProvider extends ChangeNotifier {
  List<LogicalServer> _servers = [];
  bool _isLoading = false;
  String? _error;

  List<LogicalServer> get servers => _servers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadServers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // TODO: Replace with actual API call to fetch servers
      // _servers = await _api.getServers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
