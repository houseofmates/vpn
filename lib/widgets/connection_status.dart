import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';

class ConnectionStatus extends StatelessWidget {
  const ConnectionStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, _) {
        final isConnected = connectionProvider.isConnected;
        final isConnecting = connectionProvider.isConnecting;
        final connectedSeconds = connectionProvider.connectedSeconds;

        return Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).cardTheme.color,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'connection status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (isConnecting)
                const Text(
                  'connecting...',
                  style: TextStyle(color: Colors.orange),
                )
              else if (isConnected)
                Text(
                  'connected for ${_formatDuration(connectedSeconds)}',
                  style: const TextStyle(color: Colors.green),
                )
              else
                const Text(
                  'disconnected',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}