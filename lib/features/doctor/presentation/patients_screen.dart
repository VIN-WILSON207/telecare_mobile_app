import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/auth_state.dart';
import 'views/doctor_patients_view.dart';
import '../../../shared/presentation/bottom_nav_bar.dart';
import '../../../shared/presentation/telecare_tab_app_bar.dart';
import '../../../core/theme/app_theme.dart';

class PatientsScreen extends ConsumerWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view patients.')),
      );
    }

    final user = authState.user;
    final isProfessional = user.role.isHealthcareProfessional;

    return TeleCareHomeBackScope(
      currentPath: '/patients',
      child: Scaffold(
        backgroundColor: AppTheme.neutralBackground,
        appBar: TeleCareTabAppBar(title: 'My Patients', user: user),
        body: isProfessional
            ? DoctorPatientsView(user: user)
            : const Center(
                child: Text(
                  'Access restricted to certified medical practitioners.',
                  style: TextStyle(color: AppTheme.neutralMedium),
                ),
              ),
        bottomNavigationBar: isProfessional
            ? const DoctorBottomNavBar(currentPath: '/patients')
            : const PatientBottomNavBar(currentPath: '/patients'),
      ),
    );
  }
}
