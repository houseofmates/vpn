import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/server_provider.dart';
import '../widgets/server_list_item.dart';
import '../widgets/connection_status.dart';
import '../widgets/kill_switch.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load servers
    Provider.of<ServerProvider>(context, listen: false).loadServers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Connection status and kill switch
            const ConnectionStatus(),
            const KillSwitch(),
            const Divider(height: 1),
            // Server list
            Expanded(
              child: Consumer<ServerProvider>(
                builder: (context, serverProvider, _) {
                  if (serverProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (serverProvider.error != null) {
                    return Center(
                      child: Text(
                        'Error: ${serverProvider.error}',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    );
                  }
                  final servers = serverProvider.servers;
                  if (servers.isEmpty) {
                    return const Center(child: Text('no servers available'));
                  }
                  return ListView.builder(
                    itemCount: servers.length,
                    itemBuilder: (context, index) {
                      final server = servers[index];
                      return ServerListItem(server: server);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}