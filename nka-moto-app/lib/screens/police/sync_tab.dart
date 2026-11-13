import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../theme.dart';

class SyncTab extends StatefulWidget {
  const SyncTab({super.key, required this.api});
  final ApiClient api;

  @override
  State<SyncTab> createState() => _SyncTabState();
}

class _SyncTabState extends State<SyncTab> {
  Map<String, dynamic>? pack;
  String? error;
  bool loading = false;

  Future<void> download() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await widget.api.get('/sync/stolen-pack', auth: true);
      setState(() => pack = data);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Hors-ligne', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Téléchargez le pack avant une zone sans réseau.'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pack == null ? 'Aucun pack chargé' : '${pack!['count'] ?? 0} motos volées'),
              if (pack != null) Text('Expire : ${pack!['expiresAt'] ?? ''}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: loading ? null : download,
                child: Text(loading ? 'Téléchargement...' : pack == null ? 'Télécharger le pack' : 'Mettre à jour le pack'),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 16),
        if (pack != null)
          ...(pack!['items'] is List ? pack!['items'] as List : []).map((i) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: NkaColors.red,
                    child: Icon(Icons.two_wheeler, color: Colors.white),
                  ),
                  title: Text('${i['brand']} ${i['model']}'),
                  subtitle: Text(i['theftLocation'] ?? 'Lieu inconnu'),
                ),
              )),
      ],
    );
  }
}
