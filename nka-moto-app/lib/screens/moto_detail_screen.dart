import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../theme.dart';
import '../widgets/photo_slot.dart';
import 'report_theft_screen.dart';

class MotoDetailScreen extends StatefulWidget {
  const MotoDetailScreen({super.key, required this.api, required this.motorcycleId});
  final ApiClient api;
  final String motorcycleId;

  @override
  State<MotoDetailScreen> createState() => _MotoDetailScreenState();
}

class _MotoDetailScreenState extends State<MotoDetailScreen> {
  Map<String, dynamic>? moto;
  List reports = [];
  String? error;
  String? declarationPath;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await widget.api.get('/motorcycles/${widget.motorcycleId}', auth: true);
      final mine = await widget.api.get('/theft-reports/mine', auth: true);
      setState(() {
        moto = data;
        reports = (mine is List ? mine : []).where((r) => r['motorcycleId'] == widget.motorcycleId).toList();
        error = null;
      });
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> uploadDeclaration(String reportId, String path) async {
    setState(() => uploading = true);
    try {
      final uploaded = await widget.api.uploadFile(path);
      await widget.api.post('/theft-reports/$reportId/loss-declaration', {
        'url': uploaded['url'],
        'storagePath': uploaded['storagePath'],
        'mimeType': uploaded['mimeType'],
        'sizeBytes': uploaded['sizeBytes'],
      }, auth: true);
      await load();
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final validated = reports.cast<Map>().where((r) => r['status'] == 'VALIDATED').toList();
    final pendingDecl = validated.where((r) => r['declarationUploadedAt'] == null).toList();

    return Scaffold(
      appBar: AppBar(title: Text(moto == null ? 'Moto' : '${moto!['brand']} ${moto!['model']}')),
      body: moto == null
          ? Center(child: error != null ? Text(error!) : const CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('${moto!['brand']} ${moto!['model']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Châssis : ${moto!['chassisMasked'] ?? ''}'),
                Text('Statut : ${moto!['status']}'),
                if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                if (moto!['status'] != 'STOLEN')
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportTheftScreen(api: widget.api, motorcycleId: widget.motorcycleId),
                        ),
                      );
                      load();
                    },
                    child: const Text('Signaler un vol'),
                  ),
                if (pendingDecl.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: NkaColors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Ajoutez la photo de la déclaration de perte sous 48h.'),
                  ),
                  const SizedBox(height: 8),
                  PhotoSlot(
                    label: 'Déclaration de perte',
                    path: declarationPath,
                    onPicked: (p) {
                      setState(() => declarationPath = p);
                      uploadDeclaration(pendingDecl.first['id'], p);
                    },
                  ),
                  if (uploading) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
                ],
              ],
            ),
    );
  }
}
