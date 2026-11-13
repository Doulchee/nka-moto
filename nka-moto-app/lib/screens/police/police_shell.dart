import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../theme.dart';
import '../phone_screen.dart';
import 'history_tab.dart';
import 'search_tab.dart';
import 'sync_tab.dart';

class PoliceShell extends StatefulWidget {
  const PoliceShell({super.key, required this.api});
  final ApiClient api;

  @override
  State<PoliceShell> createState() => _PoliceShellState();
}

class _PoliceShellState extends State<PoliceShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      SearchTab(api: widget.api),
      HistoryTab(api: widget.api),
      SyncTab(api: widget.api),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: NkaColors.navy,
        title: const Text('N’ka Moto · Autorités'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await widget.api.clearTokens();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => PhoneScreen(api: widget.api)),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Contrôle'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historique'),
          NavigationDestination(icon: Icon(Icons.cloud_download), label: 'Hors-ligne'),
        ],
      ),
    );
  }
}
