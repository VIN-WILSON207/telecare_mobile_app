import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/models/user_model.dart';
import 'views/patient_dashboard_view.dart';
import '../../../shared/presentation/bottom_nav_bar.dart';
import '../../../shared/presentation/telecare_tab_app_bar.dart';
import '../../../core/theme/app_theme.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key, required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.neutralBackground,
      appBar: TeleCareTabAppBar(title: 'TeleCare', user: user),
      body: PatientDashboardView(user: user),
      bottomNavigationBar: const PatientBottomNavBar(currentPath: '/home'),
    );
  }
}
