import 'package:flutter/foundation.dart';
import 'package:system_tray/system_tray.dart';
import '../providers/connection_provider.dart';

class SystemTrayService {
  final ConnectionProvider _connectionProvider;
  SystemTrayService(this._connectionProvider);

  Future<void> init() async {
    if (!kIsWeb) {
      await SystemTray.instance.initSystemTray(
        menu: [
          SystemTrayMenuItem(
            label: 'Connect',
            clicked: () async {
              // We need to connect to a server; for simplicity, we'll connect to the first free server.
              // In a real app, we might want to show a menu of servers.
              // We'll just show a message for now.
              // TODO: Implement server selection from tray.
            },
          ),
          SystemTrayMenuItem(
            label: 'Disconnect',
            clicked: () async {
              await _connectionProvider.disconnect();
            },
          ),
          SystemTrayMenuItem(
            label: 'Quit',
            clicked: () async {
              await SystemTray.instance.exitApp();
            },
          ),
        ],
        // ToolTip is optional
        toolTip: 'VPN Client',
      );

      // Register a click event if needed
      SystemTray.instance.registerSystemTrayEventHandler((eventName) {
        if (kDebugMode) {
          print('System tray event: $eventName');
        }
        // Handle events like right-click, double-click, etc.
        // We can toggle the connection on click, for example.
        if (eventName == kSystemTrayEvent.click) {
          // Left-click: toggle connection
          if (_connectionProvider.isConnected) {
            _connectionProvider.disconnect();
          } else {
            // Connect to a default server? We'll need to implement.
          }
        }
        return false;
      });
    }
  }

  Future<void> dispose() async {
    if (!kIsWeb) {
      await SystemTray.instance.disposeSystemTray();
    }
  }
}