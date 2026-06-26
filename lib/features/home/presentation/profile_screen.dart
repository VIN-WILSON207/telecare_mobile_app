import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/auth_state.dart';
import '../../auth/data/models/user_role.dart';
import '../../patient/presentation/views/patient_profile_view.dart';
import '../../doctor/presentation/views/doctor_profile_view.dart';
import '../../../shared/presentation/telecare_tab_app_bar.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view profile.')),
      );
    }

    final user = authState.user;

    return Scaffold(
      backgroundColor: AppTheme.neutralBackground,
      appBar: TeleCareTabAppBar(
        title: 'My Profile',
        user: user,
        showBackButton: true,
        showProfileButton: false,
      ),
      body: user.role == UserRole.doctor
          ? DoctorProfileView(user: user)
          : PatientProfileView(user: user),
    );
  }
}
