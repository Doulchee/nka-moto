import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../theme.dart';
import 'public_fiche_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.api});
  final ApiClient api;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Map<String, dynamic>? stats;
  List feed = [];
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final s = await widget.api.get('/stats');
      final f = await widget.api.get('/feed');
      setState(() {
        stats = s;
        feed = f is List ? f : [];
        error = null;
      });
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Tableau de bord', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
          Row(
            children: [
              _StatCard(label: 'En recherche', value: '${stats?['motosEnRecherche'] ?? '-'}', color: NkaColors.red),
              const SizedBox(width: 12),
              _StatCard(label: 'Retrouvées', value: '${stats?['motosRetrouvees'] ?? '-'}', color: NkaColors.green),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Motos recherchées', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (feed.isEmpty) const Text('Aucun signalement validé pour le moment.'),
          ...feed.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: item['shareCode'] == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PublicFicheScreen(api: widget.api, shareCode: item['shareCode']),
                            ),
                          );
                        },
                  leading: const CircleAvatar(backgroundColor: NkaColors.red, child: Icon(Icons.two_wheeler, color: Colors.white)),
                  title: Text('${item['brand'] ?? ''} ${item['model'] ?? ''}'),
                  subtitle: Text('${item['locationText'] ?? 'Lieu inconnu'}\n${item['theftDatetime'] ?? ''}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                ),
              )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            Text(label),
          ],
        ),
      ),
    );
  }
}
