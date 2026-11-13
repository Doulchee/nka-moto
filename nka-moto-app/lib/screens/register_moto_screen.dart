import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../widgets/photo_slot.dart';

class RegisterMotoScreen extends StatefulWidget {
  const RegisterMotoScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<RegisterMotoScreen> createState() => _RegisterMotoScreenState();
}

class _RegisterMotoScreenState extends State<RegisterMotoScreen> {
  final brand = TextEditingController();
  final model = TextEditingController();
  final color = TextEditingController();
  final chassis = TextEditingController();
  final plate = TextEditingController();
  String? invoicePath;
  String? cardPath;
  String? chassisPhotoPath;
  String? motoPhotoPath;
  bool loading = false;
  String? error;

  Future<void> _attach(String motoId, String type, String path) async {
    final uploaded = await widget.api.uploadFile(path);
    await widget.api.post('/motorcycles/$motoId/files', {
      'type': type,
      'url': uploaded['url'],
      'storagePath': uploaded['storagePath'],
      'mimeType': uploaded['mimeType'],
      'sizeBytes': uploaded['sizeBytes'],
    }, auth: true);
  }

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final moto = await widget.api.post('/motorcycles', {
        'brand': brand.text,
        'model': model.text,
        'color': color.text,
        'chassisNumber': chassis.text,
        'plateNumber': plate.text.isEmpty ? null : plate.text,
      }, auth: true);
      final id = moto['id'] as String;
      if (!kIsWeb) {
        if (invoicePath != null) await _attach(id, 'INVOICE', invoicePath!);
        if (cardPath != null) await _attach(id, 'REGISTRATION_CARD', cardPath!);
        if (chassisPhotoPath != null) await _attach(id, 'PHOTO_CHASSIS', chassisPhotoPath!);
        if (motoPhotoPath != null) await _attach(id, 'MOTO_PHOTO', motoPhotoPath!);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enregistrer une moto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: brand, decoration: const InputDecoration(labelText: 'Marque', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: model, decoration: const InputDecoration(labelText: 'Modèle', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: color, decoration: const InputDecoration(labelText: 'Couleur', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: chassis, decoration: const InputDecoration(labelText: 'N° de châssis', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: plate, decoration: const InputDecoration(labelText: 'Plaque (optionnel)', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          const Text('Photos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          if (kIsWeb)
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text('Sur Chrome les photos sont désactivées (limite Flutter Web). Enregistre la moto sans photo.'),
            ),
          if (!kIsWeb) const SizedBox(height: 8),
          if (!kIsWeb) Row(children: [
            Expanded(child: PhotoSlot(label: 'Facture', path: invoicePath, onPicked: (p) => setState(() => invoicePath = p))),
            const SizedBox(width: 8),
            Expanded(child: PhotoSlot(label: 'Carte grise', path: cardPath, onPicked: (p) => setState(() => cardPath = p))),
          ]),
          if (!kIsWeb) const SizedBox(height: 8),
          if (!kIsWeb) Row(children: [
            Expanded(child: PhotoSlot(label: 'Photo châssis', path: chassisPhotoPath, onPicked: (p) => setState(() => chassisPhotoPath = p))),
            const SizedBox(width: 8),
            Expanded(child: PhotoSlot(label: 'Photo moto', path: motoPhotoPath, onPicked: (p) => setState(() => motoPhotoPath = p))),
          ]),
          if (error != null) ...[const SizedBox(height: 12), Text(error!, style: const TextStyle(color: Colors.red))],
          const SizedBox(height: 24),
          ElevatedButton(onPressed: loading ? null : submit, child: Text(loading ? 'Enregistrement...' : 'Enregistrer')),
        ],
      ),
    );
  }
}
