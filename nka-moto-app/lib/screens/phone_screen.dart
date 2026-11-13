import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'otp_screen.dart';
import 'police/authority_login_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final controller = TextEditingController(text: '+223');
  bool loading = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await widget.api.post('/auth/otp/request', {'phone': controller.text.trim()});
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            api: widget.api,
            phone: controller.text.trim(),
            debugCode: res is Map ? res['debugCode']?.toString() : null,
          ),
        ),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              const Text('N’KA MOTO', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Connectez-vous avec votre numéro de téléphone'),
              const SizedBox(height: 32),
              TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  hintText: '+223XXXXXXXX',
                  border: OutlineInputBorder(),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: loading ? null : submit,
                child: Text(loading ? 'Envoi...' : 'Recevoir le code'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AuthorityLoginScreen(api: widget.api)),
                  );
                },
                child: const Text('Espace autorités'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
