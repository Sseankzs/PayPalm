import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/financial_dashboard_screen.dart';
import 'screens/bank_management_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
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
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/transactions': (context) {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) {
            // Redirect to login or show error
            return const SignupScreen();
          }
          return TransactionHistoryScreen(uid: uid);
        },
        '/dashboard': (context) {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) {
            return const SignupScreen();
          }
          return DashboardScreen(uid: uid);
        },
        '/bank_management': (context) {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) {
            return const SignupScreen();
          }
          return BankManagementScreen(uid: uid);
        },
        '/profile': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            return const SignupScreen();
          }
          return ProfileScreen(uid: user.uid, email: user.email ?? '');
        },
      },
    );
  }
}
