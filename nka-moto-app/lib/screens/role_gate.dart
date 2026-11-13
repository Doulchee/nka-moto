import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'phone_screen.dart';
import 'police/police_shell.dart';
import 'shell_screen.dart';

class RoleGate extends StatefulWidget {
  const RoleGate({super.key, required this.api});
  final ApiClient api;

  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  Widget? dest;
  String? error;

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    try {
      final token = await widget.api.currentToken();
      if (token == null || token.isEmpty) {
        setState(() => dest = PhoneScreen(api: widget.api));
        return;
      }
      final me = await widget.api.get('/auth/me', auth: true);
      final role = me['role']?.toString() ?? 'CITIZEN';
      await widget.api.saveRole(role);
      if (!mounted) return;
      if (role == 'AUTHORITY' || role == 'ADMIN') {
        setState(() => dest = PoliceShell(api: widget.api));
      } else {
        setState(() => dest = ShellScreen(api: widget.api));
      }
    } catch (_) {
      await widget.api.clearTokens();
      if (!mounted) return;
      setState(() => dest = PhoneScreen(api: widget.api));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (dest == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return dest!;
  }
}
