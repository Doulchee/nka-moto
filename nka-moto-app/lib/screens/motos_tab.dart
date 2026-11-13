import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../theme.dart';
import 'moto_detail_screen.dart';
import 'register_moto_screen.dart';

class MotosTab extends StatefulWidget {
  const MotosTab({super.key, required this.api});
  final ApiClient api;

  @override
  State<MotosTab> createState() => _MotosTabState();
}

class _MotosTabState extends State<MotosTab> {
  List motos = [];
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await widget.api.get('/motorcycles/mine', auth: true);
      setState(() {
        motos = data is List ? data : [];
        error = null;
      });
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Color statusColor(String? status) {
    switch (status) {
      case 'STOLEN':
        return NkaColors.red;
      case 'RECOVERED':
        return NkaColors.green;
      default:
        return NkaColors.primary;
    }
  }

  String statusLabel(String? status) {
    switch (status) {
      case 'STOLEN':
        return 'En recherche';
      case 'RECOVERED':
        return 'Retrouvée';
      default:
        return 'Enregistrée';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterMotoScreen(api: widget.api)));
          load();
        },
        backgroundColor: NkaColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Enregistrer'),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            const Text('Mes motos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Enregistrer, suivre, signaler'),
            const SizedBox(height: 16),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            if (motos.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Text('Aucune moto pour l’instant.\nAppuyez sur Enregistrer.'),
              ),
            ...motos.map((m) {
              final color = statusColor(m['status']);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MotoDetailScreen(api: widget.api, motorcycleId: m['id']),
                      ),
                    );
                    load();
                  },
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(Icons.two_wheeler, color: color),
                  ),
                  title: Text('${m['brand']} ${m['model']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${m['chassisMasked'] ?? ''}\n${m['color'] ?? ''}'),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(statusLabel(m['status']), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
