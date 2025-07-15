import 'package:flutter/material.dart';
import '../navigation_panel.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: const Center(
        child: Text('List of past palm-based payments with timestamps.'),
      ),
     bottomNavigationBar: NavigationPanel(
        selectedIndex: 2,
        onItemTapped: (index) {
          // Handle navigation logic here, e.g.:
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/bank');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/transactions');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
}
