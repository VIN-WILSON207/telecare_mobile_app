import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/presentation/bottom_nav_bar.dart';
import '../../../shared/presentation/telecare_tab_app_bar.dart';
import '../../auth/data/models/user_role.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/auth_state.dart';
import 'screens/consultation_history_screen.dart';

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
    final title = isDoctor ? 'Consultation Records' : 'Previous Consultations';

    return TeleCareHomeBackScope(
      currentPath: '/consultations',
      child: Scaffold(
        backgroundColor: AppTheme.neutralBackground,
        appBar: TeleCareTabAppBar(title: title, user: user),
        body: ConsultationHistoryScreen(user: user),
        bottomNavigationBar: isDoctor
            ? const DoctorBottomNavBar(currentPath: '/consultations')
            : const PatientBottomNavBar(currentPath: '/home'),
      ),
    );
  }
}
