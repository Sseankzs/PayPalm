import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/profile_screen.dart';
import 'screens/financial_dashboard_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/bank_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const PalmPayApp());
}

class PalmPayApp extends StatelessWidget {
  const PalmPayApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'PalmPay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/dashboard', // You control this
      routes: {
        '/profile': (context) => const ProfileScreen(),
        '/dashboard': (context) => const SpendingDashboardScreen(),
        '/transactions': (context) => const TransactionHistoryScreen(),
        '/bank': (context) => const BankManagementScreen(),
      },
    );
  }
}
