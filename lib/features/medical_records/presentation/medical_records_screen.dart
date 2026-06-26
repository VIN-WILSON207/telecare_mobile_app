import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/auth_state.dart';
import '../../auth/data/models/user_role.dart';
import '../../patient/presentation/views/patient_records_view.dart';
import '../../../shared/presentation/bottom_nav_bar.dart';
import '../../../shared/presentation/telecare_tab_app_bar.dart';
import '../../../core/theme/app_theme.dart';

class MedicalRecordsScreen extends ConsumerWidget {
  const MedicalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view medical records.')),
      );
    }

    final user = authState.user;
    final isDoctor = user.role == UserRole.doctor;

    return Scaffold(
      backgroundColor: AppTheme.neutralBackground,
      appBar: TeleCareTabAppBar(
        title: isDoctor ? 'Medical Records' : 'My Medical Records',
        user: user,
      ),
      body: user.role == UserRole.patient
          ? PatientRecordsView(user: user)
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_shared_rounded, size: 48, color: AppTheme.neutralLight),
                    SizedBox(height: 12),
                    Text(
                      'Patient Medical Records',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.neutralDark),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Search patients in your Patients tab to request access to their diagnostic history and medical files.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: isDoctor
          ? const DoctorBottomNavBar(currentPath: '/medical-records')
          : const PatientBottomNavBar(currentPath: '/medical-records'),
    );
  }
}
