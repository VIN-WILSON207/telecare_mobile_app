import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/models/user_role.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/auth_state.dart';
import '../../patient/presentation/patient_home_screen.dart';
import '../../doctor/presentation/doctor_home_screen.dart';
import '../../admin/dashboard/admin_shell_screen.dart';

/// Smart home screen that dispatches to the correct role-specific dashboard.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState is AuthLoading || authState is AuthInitial) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(
          child: Text('Session expired. Please sign in again.'),
        ),
      );
    }

    final user = authState.user;

    // Route to role-specific dashboard
    switch (user.role) {
      case UserRole.doctor:
        return DoctorHomeScreen(user: user);
      case UserRole.patient:
        return PatientHomeScreen(user: user);
      case UserRole.admin:
        return const AdminShellScreen();
      case UserRole.nurse:
      case UserRole.labTechnician:
        // For now, treat other healthcare professionals similarly to doctors or show a coming soon
        return DoctorHomeScreen(user: user);
    }
  }
}
