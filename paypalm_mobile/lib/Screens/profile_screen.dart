import 'package:flutter/material.dart';
import '../navigation_panel.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(
        child: Text('User information, app preferences, and palm hash.'),
      ),
        bottomNavigationBar: NavigationPanel(
        selectedIndex: 3,
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