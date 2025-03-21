import 'package:bank_app/auth_services/user_auth.dart';
import 'package:bank_app/screens/home_screen.dart';
import 'package:bank_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return authProvider.user == null ? LoginScreen() : const HomeScreen();
  }
}
