import 'package:flutter/material.dart';

class BankManagementScreen extends StatelessWidget {
  const BankManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Linked Accounts')),
      body: const Center(
        child: Text('List and manage linked banks or wallets.'),
      ),
    );
  }
}