import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../theme.dart';
import 'change_password_screen.dart';
import 'police_shell.dart';

class AuthorityLoginScreen extends StatefulWidget {
  const AuthorityLoginScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<AuthorityLoginScreen> createState() => _AuthorityLoginScreenState();
}

class _AuthorityLoginScreenState extends State<AuthorityLoginScreen> {
  final idCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await widget.api.post('/auth/authority/login', {
        'professionalId': idCtrl.text.trim(),
        'password': passCtrl.text,
      });
      await widget.api.saveSession(
        access: data['accessToken'],
        refresh: data['refreshToken'],
        role: data['user']?['role'] ?? 'AUTHORITY',
      );
      if (!mounted) return;
      final mustChange = data['user']?['mustChangePassword'] == true;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => mustChange
              ? ChangePasswordScreen(api: widget.api)
              : PoliceShell(api: widget.api),
        ),
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
      backgroundColor: NkaColors.navy,
      appBar: AppBar(backgroundColor: NkaColors.navy, title: const Text('Espace autorités')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Connexion professionnelle', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Identifiant validé par l’administration', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            TextField(
              controller: idCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Identifiant professionnel',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
            ),
            if (error != null) ...[const SizedBox(height: 12), Text(error!, style: const TextStyle(color: Colors.redAccent))],
            const Spacer(),
            ElevatedButton(
              onPressed: loading ? null : submit,
              child: Text(loading ? 'Connexion...' : 'Entrer'),
            ),
          ],
        ),
      ),
    );
  }
}
