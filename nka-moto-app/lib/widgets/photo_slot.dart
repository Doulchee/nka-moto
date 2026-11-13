import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';

class PhotoSlot extends StatelessWidget {
  const PhotoSlot({
    super.key,
    required this.label,
    required this.path,
    required this.onPicked,
  });

  final String label;
  final String? path;
  final ValueChanged<String> onPicked;

  Future<void> _pick(BuildContext context) async {
    final picker = ImagePicker();
    ImageSource? source = ImageSource.gallery;
    if (!kIsWeb) {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Appareil photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    }
    if (source == null) return;
    final file = await picker.pickImage(source: source, imageQuality: 75);
    if (file != null) onPicked(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          border: Border.all(color: NkaColors.primary.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: path == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined),
                  const SizedBox(height: 6),
                  Text(label, textAlign: TextAlign.center),
                ],
              )
            : const Center(child: Icon(Icons.check_circle, color: NkaColors.green, size: 36)),
      ),
    );
  }
}
