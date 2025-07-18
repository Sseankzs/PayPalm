import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../navigation_panel.dart';
import 'financial_dashboard_screen.dart';
import 'bank_management_screen.dart';
import 'transaction_history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get email => FirebaseAuth.instance.currentUser?.email ?? '';

  List<Widget> get _pages => [
    DashboardScreen(uid: uid),
    BankManagementScreen(uid: uid),
    TransactionHistoryScreen(uid: uid),
    ProfileScreen(uid: uid, email: email),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Current UID: $uid');
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationPanel(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
