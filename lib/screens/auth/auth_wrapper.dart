import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to AuthProvider changes
    // verify the auth status
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authProvider.isAuthenticated && authProvider.user != null) {
      // User is logged in -> Show Home Screen
      return const HomeScreen();
    } else {
      // User is NOT logged in -> Show Login Screen
      return const LoginScreen();
    }
  }
}
