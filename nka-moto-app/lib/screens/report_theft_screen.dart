import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'public_fiche_screen.dart';

class ReportTheftScreen extends StatefulWidget {
  const ReportTheftScreen({super.key, required this.api, required this.motorcycleId});
  final ApiClient api;
  final String motorcycleId;

  @override
  State<ReportTheftScreen> createState() => _ReportTheftScreenState();
}

class _ReportTheftScreenState extends State<ReportTheftScreen> {
  final location = TextEditingController();
  final description = TextEditingController();
  bool loading = false;
  String? message;
  String? shareCode;

  Future<void> submit() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      final res = await widget.api.post('/theft-reports', {
        'motorcycleId': widget.motorcycleId,
        'locationText': location.text,
        'description': description.text,
        'theftDatetime': DateTime.now().toUtc().toIso8601String(),
      }, auth: true);
      setState(() {
        shareCode = res['shareCode']?.toString();
        message = res['validation'] == 'AUTO'
            ? 'Signalement validé. La moto est maintenant en rouge. Ajoutez la déclaration de perte sous 48h.'
            : (res['message'] ?? 'Signalement envoyé, en attente de validation.');
      });
    } catch (e) {
      setState(() => message = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signaler un vol')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: location, decoration: const InputDecoration(labelText: 'Lieu du vol', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
            controller: description,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
          ),
          if (message != null) ...[const SizedBox(height: 12), Text(message!)],
          if (shareCode != null && message != null && message!.contains('validé')) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicFicheScreen(api: widget.api, shareCode: shareCode!),
                  ),
                );
              },
              child: const Text('Voir et partager la fiche'),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(onPressed: loading ? null : submit, child: Text(loading ? 'Envoi...' : 'Signaler')),
        ],
      ),
    );
  }
}
