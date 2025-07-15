import 'package:flutter/material.dart';

class SpendingDashboardScreen extends StatelessWidget {
  const SpendingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spending Dashboard')),
      body: const Center(
        child: Text('Visual summary of recent transactions and spending habits.'),
      ),
    );
  }
}