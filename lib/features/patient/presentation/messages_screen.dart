import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/auth_state.dart';
import '../../auth/data/models/user_role.dart';
import 'views/patient_messages_view.dart';
import '../../../shared/presentation/bottom_nav_bar.dart';
import '../../../shared/presentation/telecare_tab_app_bar.dart';
import '../../../core/theme/app_theme.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view messages.')),
      );
    }

    final user = authState.user;

    return Scaffold(
      backgroundColor: AppTheme.neutralBackground,
      appBar: TeleCareTabAppBar(title: 'Chats & Messages', user: user),
      body: user.role == UserRole.patient
          ? PatientMessagesView(user: user)
          : const Center(
              child: Text(
                'Doctor messages are managed through active consultations.',
                style: TextStyle(color: AppTheme.neutralMedium),
              ),
            ),
      bottomNavigationBar: user.role == UserRole.doctor
          ? const DoctorBottomNavBar(currentPath: '/messages')
          : const PatientBottomNavBar(currentPath: '/messages'),
    );
  }
}
