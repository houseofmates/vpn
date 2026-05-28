import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/server.dart';
import '../services/wireguard_service.dart';
import '../providers/connection_provider.dart';

class ServerListItem extends StatelessWidget {
  final LogicalServer server;

  const ServerListItem({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, _) {
        final isConnected = connectionProvider.isConnected;
        final isConnecting = connectionProvider.isConnecting;
        final currentServer = connectionProvider.currentServer;

        return Card(
          color: Theme.of(context).cardTheme.color,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: // We don't have flag icons yet, we can use a placeholder
                Container(
              width: 40,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  server.exitCountry.length >= 2
                      ? server.exitCountry.substring(0, 2).toUpperCase()
                      : '--',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            title: Text(
              server.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Load: ${server.load.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (server.servers.isNotEmpty)
                  Text(
                    'Domain: ${server.servers.first.domain}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: isConnecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : isConnected && currentServer == server.name
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : ElevatedButton(
                        onPressed: isConnected || isConnecting
                            ? null
                            : () async {
                                await connectionProvider.connectToServer(server);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Connect'),
                      ),
          ),
        );
      },
    );
  }
}