import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../api/api_client.dart';
import '../theme.dart';

class PublicFicheScreen extends StatefulWidget {
  const PublicFicheScreen({super.key, required this.api, required this.shareCode});
  final ApiClient api;
  final String shareCode;

  @override
  State<PublicFicheScreen> createState() => _PublicFicheScreenState();
}

class _PublicFicheScreenState extends State<PublicFicheScreen> {
  Map<String, dynamic>? fiche;
  String? error;

  String get shareUrl => '${widget.api.baseUrl}/r/${widget.shareCode}';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await widget.api.get('/r/${widget.shareCode}');
      setState(() => fiche = data);
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> share() async {
    final brand = fiche?['brand'] ?? '';
    final model = fiche?['model'] ?? '';
    await Share.share(
      'Moto volée : $brand $model.\nVoir la fiche N’ka Moto : $shareUrl',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fiche de recherche')),
      body: fiche == null
          ? Center(child: error != null ? Text(error!) : const CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (fiche!['photoUrl'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network('${widget.api.baseUrl}${fiche!['photoUrl']}', height: 200, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 12),
                Text('${fiche!['brand']} ${fiche!['model']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Couleur : ${fiche!['color'] ?? '-'}'),
                Text('Lieu : ${fiche!['locationText'] ?? '-'}'),
                Text('Date : ${fiche!['theftDatetime'] ?? '-'}'),
                if (fiche!['description'] != null) Text(fiche!['description']),
                const SizedBox(height: 12),
                const Text('Signalement officiel N’ka Moto. Contactez la police ou la gendarmerie.'),
                const SizedBox(height: 24),
                ElevatedButton.icon(onPressed: share, icon: const Icon(Icons.share), label: const Text('Partager la fiche')),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('« J’ai vu cette moto » : contact autorités à brancher plus tard.')),
                    );
                  },
                  child: const Text('J’ai vu cette moto'),
                ),
              ],
            ),
    );
  }
}
