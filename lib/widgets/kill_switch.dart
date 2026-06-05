import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';

class KillSwitch extends StatelessWidget {
  const KillSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, _) {
        final isConnected = connectionProvider.isConnected;
        return SwitchListTile(
          title: const Text('kill switch'),
          subtitle: const Text('blocks internet traffic if vpn disconnects'),
          value: false, // We'll implement later
          onChanged: isConnected ? (value) {} : null,
          secondary: const Icon(Icons.security),
          activeColor: Theme.of(context).colorScheme.primary,
        );
      },
    );
  }
}