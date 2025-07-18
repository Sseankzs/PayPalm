import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/financial_dashboard_screen.dart';
import 'screens/bank_management_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const PayPalmApp());
}

class PayPalmApp extends StatelessWidget {
  const PayPalmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayPalm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: Colors.black87,
                displayColor: Colors.indigo,
              ),
        ).copyWith(
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.indigo[900],
          ),
          titleMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.indigo,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
          labelLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
          // Add more as needed
        ),
        // You can also set elevatedButtonTheme, inputDecorationTheme, etc.
      ),
      home: const AuthGate(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/transactions': (context) {
          final uid = FirebaseAuth.instance.currentUser?.uid ?? 'uZsYmasM5B3dVXTYjt3J';
          return TransactionHistoryScreen(uid: uid);
        },
        '/dashboard': (context) {
          final uid = FirebaseAuth.instance.currentUser?.uid ?? 'uZsYmasM5B3dVXTYjt3J';
          return DashboardScreen(uid: uid);
        },
        '/bank_management': (context) {
          final uid = FirebaseAuth.instance.currentUser?.uid ?? 'uZsYmasM5B3dVXTYjt3J';
          return BankManagementScreen(uid: uid);
        },
        '/profile': (context) {
          final uid = FirebaseAuth.instance.currentUser?.uid ?? 'uZsYmasM5B3dVXTYjt3J';
          final email = FirebaseAuth.instance.currentUser?.email ?? '';
          return ProfileScreen(uid: uid, email: email);
        },
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // If user is logged in, go to HomeScreen
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }
        // Else, show SignupScreen
        return const SignupScreen();
      },
    );
  }
}
