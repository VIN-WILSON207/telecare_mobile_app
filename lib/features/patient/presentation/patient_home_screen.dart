import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/models/user_model.dart';
import '../../auth/providers/auth_providers.dart';
import 'views/patient_dashboard_view.dart';
import '../../../shared/presentation/bottom_nav_bar.dart';
import '../../../shared/presentation/telecare_home_chrome.dart';
import '../../../core/theme/app_theme.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key, required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.neutralBackground,
      appBar: TeleCareHomeAppBar(user: user),
      drawer: TeleCareDrawer(
        user: user,
        onLogout: () => ref.read(authNotifierProvider.notifier).logout(),
        items: const [
          TeleCareDrawerItem(
            label: 'Home',
            icon: Icons.home_rounded,
            route: '/home',
          ),
          TeleCareDrawerItem(
            label: 'Appointments',
            icon: Icons.calendar_month_rounded,
            route: '/appointments',
          ),
          TeleCareDrawerItem(
            label: 'Messages',
            icon: Icons.chat_bubble_rounded,
            route: '/messages',
          ),
          TeleCareDrawerItem(
            label: 'Medical Records',
            icon: Icons.folder_rounded,
            route: '/medical-records',
          ),
          TeleCareDrawerItem(
            label: 'Health Tips',
            icon: Icons.health_and_safety_rounded,
            route: '/home',
          ),
          TeleCareDrawerItem(
            label: 'Settings',
            icon: Icons.settings_rounded,
            route: '/profile',
          ),
          TeleCareDrawerItem(
            label: 'Help',
            icon: Icons.help_outline_rounded,
            route: '/profile',
          ),
        ],
      ),
      body: PatientDashboardView(user: user),
      floatingActionButton: const EmergencySosButton(),
      bottomNavigationBar: const PatientBottomNavBar(currentPath: '/home'),
    );
  }
}
