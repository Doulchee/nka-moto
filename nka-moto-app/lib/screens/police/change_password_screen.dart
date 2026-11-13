import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import 'police_shell.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final current = TextEditingController();
  final next = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await widget.api.post('/auth/authority/change-password', {
        'currentPassword': current.text,
        'newPassword': next.text,
      }, auth: true);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => PoliceShell(api: widget.api)),
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
      appBar: AppBar(title: const Text('Nouveau mot de passe')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Première connexion : choisissez un mot de passe personnel (8 caractères min).'),
            const SizedBox(height: 16),
            TextField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe temporaire', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'Nouveau mot de passe', border: OutlineInputBorder())),
            if (error != null) ...[const SizedBox(height: 12), Text(error!, style: const TextStyle(color: Colors.red))],
            const Spacer(),
            ElevatedButton(onPressed: loading ? null : submit, child: Text(loading ? 'Enregistrement...' : 'Valider')),
          ],
        ),
      ),
    );
  }
}
