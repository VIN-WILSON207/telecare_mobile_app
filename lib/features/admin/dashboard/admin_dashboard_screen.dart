import 'package:flutter/material.dart';
import 'admin_shell_screen.dart';

/// Screen wrapper that loads the main Admin Panel Dashboard.
class AdminDashboardScreen extends StatelessWidget {
  /// Constructor for AdminDashboardScreen.
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Return the shell screen which holds all admin panel tabs and views.
    return const AdminShellScreen();
  }
}
