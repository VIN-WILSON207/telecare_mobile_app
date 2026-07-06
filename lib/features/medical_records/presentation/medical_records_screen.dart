import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/auth_state.dart';
import '../../auth/data/models/user_role.dart';
import 'views/doctor_medical_records_view.dart';
import '../../patient/presentation/views/patient_records_view.dart';
import '../../../shared/presentation/bottom_nav_bar.dart';
import '../../../shared/presentation/telecare_tab_app_bar.dart';
import '../../../core/theme/app_theme.dart';

class MedicalRecordsScreen extends ConsumerWidget {
  const MedicalRecordsScreen({super.key, this.initialRecordsTab = 0});

  final int initialRecordsTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view medical records.')),
      );
    }

    final user = authState.user;
    final isProfessional = user.role.isHealthcareProfessional;

    return TeleCareHomeBackScope(
      currentPath: initialRecordsTab == 1
          ? '/prescriptions'
          : '/medical-records',
      child: Scaffold(
        backgroundColor: AppTheme.neutralBackground,
        appBar: TeleCareTabAppBar(
          title: initialRecordsTab == 1
              ? 'Prescriptions'
              : isProfessional
              ? 'Medical Records'
              : 'My Medical Records',
          user: user,
        ),
        body: user.role == UserRole.patient
            ? PatientRecordsView(user: user, initialTab: initialRecordsTab)
            : DoctorMedicalRecordsView(user: user),
        bottomNavigationBar: isProfessional
            ? const DoctorBottomNavBar(currentPath: '/medical-records')
            : const PatientBottomNavBar(currentPath: '/medical-records'),
      ),
    );
  }
}
