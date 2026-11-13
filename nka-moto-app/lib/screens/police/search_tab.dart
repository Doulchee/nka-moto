import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../theme.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key, required this.api});
  final ApiClient api;

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final query = TextEditingController();
  String type = 'AUTO';
  bool loading = false;
  Map<String, dynamic>? result;
  String? error;

  Future<void> search() async {
    setState(() {
      loading = true;
      error = null;
      result = null;
    });
    try {
      final data = await widget.api.post('/controls/search', {
        'query': query.text.trim(),
        if (type != 'AUTO') 'type': type,
      }, auth: true);
      setState(() => result = data);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (result != null) {
      final isRed = result!['result'] == 'RED';
      return Container(
        color: isRed ? NkaColors.red : NkaColors.green,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isRed ? 'ROUGE' : 'VERT', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800)),
              Text(
                isRed ? 'Moto signalée volée' : 'Moto non signalée volée',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 24),
              if (result!['motorcycle'] != null)
                Text(
                  '${result!['motorcycle']['brand']} ${result!['motorcycle']['model']}',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
                ),
              if (isRed && result!['theft'] != null) ...[
                const SizedBox(height: 16),
                Text('Vol : ${result!['theft']['date'] ?? '-'}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                Text('Lieu : ${result!['theft']['location'] ?? '-'}', style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
              if (isRed && result!['owner'] != null) ...[
                const SizedBox(height: 16),
                Text('Propriétaire : ${result!['owner']['fullName'] ?? '-'}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                Text('Tél : ${result!['owner']['phone'] ?? '-'}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: NkaColors.navy),
                  onPressed: () => setState(() => result = null),
                  child: const Text('Nouveau contrôle'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contrôle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Saisissez le châssis ou la plaque'),
          const SizedBox(height: 16),
          TextField(
            controller: query,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 20, letterSpacing: 1),
            decoration: const InputDecoration(
              labelText: 'Châssis ou plaque',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'AUTO', label: Text('Auto')),
              ButtonSegment(value: 'CHASSIS', label: Text('Châssis')),
              ButtonSegment(value: 'PLATE', label: Text('Plaque')),
            ],
            selected: {type},
            onSelectionChanged: (s) => setState(() => type = s.first),
          ),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
          const Spacer(),
          ElevatedButton(
            onPressed: loading ? null : search,
            child: Text(loading ? 'Recherche...' : 'Contrôler'),
          ),
        ],
      ),
    );
  }
}
