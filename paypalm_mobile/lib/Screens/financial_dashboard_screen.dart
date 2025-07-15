import 'package:flutter/material.dart';
import '../navigation_panel.dart';

class SpendingDashboardScreen extends StatefulWidget {
  const SpendingDashboardScreen({super.key});

  @override
  State<SpendingDashboardScreen> createState() => _SpendingDashboardScreenState();
}

class _SpendingDashboardScreenState extends State<SpendingDashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
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
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spending Dashboard')),
      body: const Center(
        child: Text('Visual summary of recent transactions and spending habits.'),
      ),
      bottomNavigationBar: NavigationPanel(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}