import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/setup_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          // Check if user exists in Firestore and has dailyTarget
          return FutureBuilder<bool>(
            future: _authService.hasDailyTarget(),
            builder: (context, hasDailyTargetSnapshot) {
              if (hasDailyTargetSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // If user doesn't have dailyTarget, show setup screen
              if (hasDailyTargetSnapshot.hasData &&
                  hasDailyTargetSnapshot.data == false) {
                return const SetupScreen();
              }

              // If user has dailyTarget, show home screen
              return const HomeScreen();
            },
          );
        }

        // If user is not logged in, show login screen
        return const LoginScreen();
      },
    );
  }
}
