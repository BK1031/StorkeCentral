import 'package:flutter/material.dart';
import 'package:storke_central/utils/theme.dart';

class CredentialsPage extends StatefulWidget {
  const CredentialsPage({Key? key}) : super(key: key);

  @override
  State<CredentialsPage> createState() => _CredentialsPageState();
}

class _CredentialsPageState extends State<CredentialsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SB_NAVY,
        title: const Text(
          "GOLD Login",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
