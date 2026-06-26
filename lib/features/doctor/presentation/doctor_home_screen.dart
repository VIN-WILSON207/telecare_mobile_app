import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/models/user_model.dart';
import 'views/doctor_dashboard_view.dart';
import '../../../shared/presentation/bottom_nav_bar.dart';
import '../../../shared/presentation/telecare_tab_app_bar.dart';
import '../../../core/theme/app_theme.dart';

class DoctorHomeScreen extends ConsumerWidget {
  const DoctorHomeScreen({super.key, required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.neutralBackground,
      appBar: TeleCareTabAppBar(title: 'TeleCare Pro', user: user),
      body: DoctorDashboardView(user: user),
      bottomNavigationBar: const DoctorBottomNavBar(currentPath: '/home'),
    );
  }
}
