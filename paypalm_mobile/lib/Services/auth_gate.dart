import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paypalm_mobile/Screens/home_screen.dart';
import 'package:paypalm_mobile/Screens/signup_screen.dart';



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