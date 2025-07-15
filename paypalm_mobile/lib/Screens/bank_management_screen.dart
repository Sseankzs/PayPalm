import 'package:flutter/material.dart';
import '../navigation_panel.dart';

class BankManagementScreen extends StatelessWidget {
  const BankManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Linked Accounts')),
      body: const Center(
        child: Text('List and manage linked banks or wallets.'),
      ),
      bottomNavigationBar: NavigationPanel(
        selectedIndex: 1,
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