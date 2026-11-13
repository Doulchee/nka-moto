import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../theme.dart';
import 'home_tab.dart';
import 'motos_tab.dart';
import 'settings_tab.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(api: widget.api),
      MotosTab(api: widget.api),
      SettingsTab(api: widget.api),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('N’ka Moto')),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        indicatorColor: NkaColors.primary.withOpacity(0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.two_wheeler_outlined), selectedIcon: Icon(Icons.two_wheeler), label: 'Motos'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Paramètres'),
        ],
      ),
    );
  }
}
