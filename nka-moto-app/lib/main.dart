import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'screens/role_gate.dart';
import 'theme.dart';

void main() {
  runApp(const NkaMotoApp());
}

class NkaMotoApp extends StatelessWidget {
  const NkaMotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient();
    return MaterialApp(
      title: 'N’ka Moto',
      debugShowCheckedModeBanner: false,
      theme: nkaTheme(),
      home: RoleGate(api: api),
    );
  }
}
