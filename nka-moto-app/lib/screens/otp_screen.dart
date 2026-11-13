import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'shell_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.api, required this.phone, this.debugCode});
  final ApiClient api;
  final String phone;
  final String? debugCode;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final controller = TextEditingController();
  final nameController = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await widget.api.post('/auth/otp/verify', {
        'phone': widget.phone,
        'code': controller.text.trim(),
        'fullName': nameController.text.trim(),
      });
      await widget.api.saveSession(
        access: data['accessToken'],
        refresh: data['refreshToken'],
        role: data['user']?['role'] ?? 'CITIZEN',
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => ShellScreen(api: widget.api)),
        (_) => false,
      );
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Code envoyé au ${widget.phone}'),
            if (widget.debugCode != null && widget.debugCode!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Code test : ${widget.debugCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const Text('(affiché seulement en développement)', style: TextStyle(fontSize: 12)),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom complet', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Code OTP', border: OutlineInputBorder()),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: loading ? null : submit,
              child: Text(loading ? 'Vérification...' : 'Valider'),
            ),
          ],
        ),
      ),
    );
  }
}
