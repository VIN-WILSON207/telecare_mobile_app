import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/models/user_role.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/auth_state.dart';
import '../../patient/presentation/views/patient_appointments_view.dart';
import '../../doctor/presentation/views/doctor_appointments_view.dart';
import '../../../shared/presentation/bottom_nav_bar.dart';
import '../../../shared/presentation/telecare_tab_app_bar.dart';
import '../../../core/theme/app_theme.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Sign in to manage appointments.')),
      );
    }

    final user = authState.user;

    if (user.role == UserRole.admin) {
      return Scaffold(
        backgroundColor: AppTheme.neutralBackground,
        appBar: TeleCareTabAppBar(title: 'Appointments', user: user),
        body: const Center(
          child: Text('Appointment management is available for patients and doctors.'),
        ),
      );
    }

    final isDoctor = user.role == UserRole.doctor;
    final title = isDoctor ? 'Appointment Requests' : 'Appointments';

    return TeleCareHomeBackScope(
      currentPath: '/appointments',
      child: Scaffold(
        backgroundColor: AppTheme.neutralBackground,
        appBar: TeleCareTabAppBar(title: title, user: user),
        body: isDoctor
            ? DoctorAppointmentsView(user: user)
            : PatientAppointmentsView(user: user),
        bottomNavigationBar: isDoctor
            ? const DoctorBottomNavBar(currentPath: '/appointments')
            : const PatientBottomNavBar(currentPath: '/appointments'),
      ),
    );
  }
}
