import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/models/user_model.dart';
import '../../auth/providers/auth_providers.dart';
import 'views/doctor_dashboard_view.dart';
import '../../../shared/presentation/bottom_nav_bar.dart';
import '../../../shared/presentation/telecare_home_chrome.dart';
import '../../../core/theme/app_theme.dart';

class DoctorHomeScreen extends ConsumerWidget {
  const DoctorHomeScreen({super.key, required this.user});
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
            label: 'Dashboard',
            icon: Icons.dashboard_rounded,
            route: '/home',
          ),
          TeleCareDrawerItem(
            label: 'Appointments',
            icon: Icons.calendar_month_rounded,
            route: '/appointments',
          ),
          TeleCareDrawerItem(
            label: 'Patients',
            icon: Icons.people_rounded,
            route: '/patients',
          ),
          TeleCareDrawerItem(
            label: 'Medical Records',
            icon: Icons.folder_shared_rounded,
            route: '/medical-records',
          ),
          TeleCareDrawerItem(
            label: 'Verification',
            icon: Icons.verified_user_rounded,
            route: '/verification-status',
          ),
          TeleCareDrawerItem(
            label: 'Reports',
            icon: Icons.bar_chart_rounded,
            route: '/home',
          ),
          TeleCareDrawerItem(
            label: 'Availability',
            icon: Icons.schedule_rounded,
            route: '/appointments',
          ),
          TeleCareDrawerItem(
            label: 'Settings',
            icon: Icons.settings_rounded,
            route: '/profile',
          ),
        ],
      ),
      body: DoctorDashboardView(user: user),
      bottomNavigationBar: const DoctorBottomNavBar(currentPath: '/home'),
    );
  }
}
