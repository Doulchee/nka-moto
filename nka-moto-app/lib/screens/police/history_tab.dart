import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../theme.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key, required this.api});
  final ApiClient api;

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List items = [];
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await widget.api.get('/controls/history', auth: true);
      setState(() {
        items = data is List ? data : [];
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
          const Text('Historique', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Contrôles de cette patrouille'),
          const SizedBox(height: 16),
          if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Text('Aucun contrôle pour le moment.'),
            ),
          ...items.map((c) {
            final red = c['result'] == 'RED';
            final moto = c['motorcycle'];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: red ? NkaColors.red : NkaColors.green,
                  child: Text(red ? 'R' : 'V', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: Text(
                  moto == null ? 'Aucun véhicule trouvé' : '${moto['brand']} ${moto['model']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${c['controlledAt'] ?? ''}${c['isOffline'] == true ? '\nHors-ligne puis synchronisé' : ''}',
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
