import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/auth_state.dart';
import '../../auth/data/models/user_role.dart';
import '../../doctor/presentation/views/doctor_consultations_view.dart';
import '../../../shared/presentation/bottom_nav_bar.dart';
import '../../../shared/presentation/telecare_tab_app_bar.dart';
import '../../../core/theme/app_theme.dart';

class ConsultationsScreen extends ConsumerWidget {
  const ConsultationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view consultations.')),
      );
    }

    final user = authState.user;
    final isDoctor = user.role == UserRole.doctor;

    return Scaffold(
      backgroundColor: AppTheme.neutralBackground,
      appBar: TeleCareTabAppBar(
        title: isDoctor ? 'Video Consultations' : 'Consultation Room',
        user: user,
      ),
      body: isDoctor
          ? DoctorConsultationsView(user: user)
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_call_rounded, size: 48, color: AppTheme.neutralLight),
                    SizedBox(height: 12),
                    Text(
                      'Consultation Room',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.neutralDark),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Approved consultations will show a join link when active. Navigate to your Appointments tab to view your bookings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: isDoctor
          ? const DoctorBottomNavBar(currentPath: '/consultations')
          : const PatientBottomNavBar(currentPath: '/home'),
    );
  }
}
