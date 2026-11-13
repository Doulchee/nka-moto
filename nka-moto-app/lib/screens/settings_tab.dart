import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../theme.dart';
import 'phone_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key, required this.api});
  final ApiClient api;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  Map<String, dynamic>? me;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await widget.api.get('/auth/me', auth: true);
      if (!mounted) return;
      setState(() {
        me = data;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    }
  }

  Future<void> logout() async {
    await widget.api.clearTokens();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => PhoneScreen(api: widget.api)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = me?['fullName']?.toString();
    final phone = me?['phone']?.toString() ?? '—';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Paramètres', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Compte citoyen'),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0x1A0B6E4F),
              child: Icon(Icons.person, color: NkaColors.primary),
            ),
            title: Text(name == null || name.isEmpty ? 'Profil' : name),
            subtitle: Text(phone),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(api: widget.api)),
              );
              load();
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline, color: NkaColors.navy),
                title: const Text('Mot de passe'),
                subtitle: const Text('Prévu après le premier OTP — pas encore actif'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le mot de passe citoyen sera ajouté après tes tests.')),
                  );
                },
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.notifications_outlined, color: NkaColors.navy),
                title: Text('Notifications'),
                subtitle: Text('Alertes de vol et rappel déclaration 48h'),
              ),
            ],
          ),
        ),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const Icon(Icons.logout, color: NkaColors.red),
            title: const Text('Se déconnecter'),
            onTap: logout,
          ),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameCtrl = TextEditingController();
  Map<String, dynamic>? me;
  bool loading = true;
  bool saving = false;
  String? message;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await widget.api.get('/auth/me', auth: true);
      nameCtrl.text = data['fullName']?.toString() ?? '';
      if (!mounted) return;
      setState(() {
        me = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        message = e.toString();
      });
    }
  }

  Future<void> save() async {
    setState(() {
      saving = true;
      message = null;
    });
    try {
      await widget.api.patch('/auth/me', {'fullName': nameCtrl.text.trim()});
      if (!mounted) return;
      setState(() => message = 'Profil enregistré');
      await load();
    } catch (e) {
      setState(() => message = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _row('Téléphone', me?['phone']?.toString() ?? '—'),
                _row('Rôle', me?['role']?.toString() ?? 'CITIZEN'),
                _row('Identifiant', me?['id']?.toString() ?? '—'),
                _row('Compte créé', me?['createdAt']?.toString() ?? '—'),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom complet', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Enregistrement...' : 'Enregistrer le nom'),
                ),
                if (message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(message!)),
                const SizedBox(height: 16),
                const Text(
                  'Le numéro ne se change pas ici. Le mot de passe arrivera après le premier enregistrement OTP.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 2),
          SelectableText(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
