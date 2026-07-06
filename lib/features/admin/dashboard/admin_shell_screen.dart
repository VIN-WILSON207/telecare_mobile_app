import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/auth_state.dart';
import '../providers/admin_providers.dart';
import 'views/dashboard_view.dart';
import '../doctor_verification/views/doctor_verification_view.dart';
import '../users/views/user_management_view.dart' as user_views;
import '../appointments/views/appointment_management_view.dart';
import '../consultations/views/consultation_monitoring_view.dart';
import '../analytics/views/analytics_view.dart';
import '../reports/views/reports_view.dart';
import '../security/views/security_center_view.dart';
import '../audit_logs/views/audit_logs_view.dart';
import '../notifications/views/notifications_view.dart';
import '../health_content/views/health_content_view.dart';
import '../feedback/views/feedback_complaints_view.dart';
import '../settings/views/settings_view.dart';
import '../backup/views/backup_recovery_view.dart';
import '../profile/views/admin_profile_view.dart';

class AdminShellScreen extends ConsumerWidget {
  const AdminShellScreen({super.key});

  // The 4 primary tabs shown in the bottom navigation bar (mobile)
  static const List<int> _bottomNavIndices = [0, 1, 2, 5];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(adminActiveTabProvider);
    final authState = ref.watch(authNotifierProvider);

    final String adminName =
        authState is AuthAuthenticated ? authState.user.fullName : 'System Admin';
    final String adminEmail =
        authState is AuthAuthenticated ? authState.user.email : 'abilavinwilson@gmail.com';

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    return PopScope(
      canPop: activeTab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && activeTab != 0) {
          ref.read(adminActiveTabProvider.notifier).setTab(0);
        }
      },
      child: Scaffold(
      backgroundColor: AppTheme.neutralBackground,
      appBar: AppBar(
        title: Text(_getAppBarTitle(activeTab)),
        centerTitle: true,
        leading: isWideScreen ? const SizedBox.shrink() : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(allUsersProvider);
              ref.invalidate(allAppointmentsProvider);
              ref.invalidate(allVerificationRequestsProvider);
              ref.invalidate(auditLogsProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing database logs...'),
                  duration: Duration(milliseconds: 700),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: isWideScreen ? null : _buildDrawer(context, ref, activeTab, adminName, adminEmail),
      body: isWideScreen
          ? Row(
              children: [
                _buildSideNavigation(context, ref, activeTab, adminName, adminEmail),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: _buildBody(activeTab)),
              ],
            )
          : _buildBody(activeTab),
      bottomNavigationBar: isWideScreen
          ? null
          : _buildBottomNav(context, ref, activeTab),
    ));
  }

  // ── Bottom Navigation Bar (Mobile) ──────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context, WidgetRef ref, int activeTab) {
    // Map the active tab to the bottom nav index
    int currentBottomIndex = _bottomNavIndices.indexOf(activeTab);
    if (currentBottomIndex < 0) currentBottomIndex = 0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                context, ref,
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                tabIndex: 0,
                isActive: activeTab == 0,
              ),
              _buildBottomNavItem(
                context, ref,
                icon: Icons.verified_user_rounded,
                label: 'Doctors',
                tabIndex: 1,
                isActive: activeTab == 1,
              ),
              _buildBottomNavItem(
                context, ref,
                icon: Icons.people_rounded,
                label: 'Users',
                tabIndex: 2,
                isActive: activeTab == 2,
              ),
              _buildBottomNavItem(
                context, ref,
                icon: Icons.bar_chart_rounded,
                label: 'Analytics',
                tabIndex: 5,
                isActive: activeTab == 5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required int tabIndex,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => ref.read(adminActiveTabProvider.notifier).setTab(tabIndex),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppTheme.primaryColor : AppTheme.neutralLight,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppTheme.primaryColor : AppTheme.neutralLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Side Navigation (Wide/Desktop) ──────────────────────────────────────────

  Widget _buildSideNavigation(
    BuildContext context,
    WidgetRef ref,
    int activeTab,
    String adminName,
    String adminEmail,
  ) {
    return Container(
      width: 260,
      color: AppTheme.cardWhite,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_rounded, color: AppTheme.primaryColor, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  adminName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  adminEmail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSectionHeader('MAIN'),
                _buildSideNavTile(ref, 0, Icons.dashboard_rounded, 'Dashboard', activeTab),
                _buildSideNavTile(ref, 1, Icons.verified_user_rounded, 'Doctor Verification', activeTab),
                _buildSideNavTile(ref, 2, Icons.people_rounded, 'Users', activeTab),
                _buildSideNavTile(ref, 3, Icons.calendar_month_rounded, 'Appointments', activeTab),
                const SizedBox(height: 8),
                _buildSectionHeader('MONITORING'),
                _buildSideNavTile(ref, 4, Icons.video_call_rounded, 'Consultations', activeTab),
                _buildSideNavTile(ref, 5, Icons.bar_chart_rounded, 'Analytics', activeTab),
                _buildSideNavTile(ref, 6, Icons.assessment_rounded, 'Reports', activeTab),
                _buildSideNavTile(ref, 7, Icons.security_rounded, 'Security', activeTab, badgeCount: 3),
                _buildSideNavTile(ref, 8, Icons.history_rounded, 'Audit Logs', activeTab),
                const SizedBox(height: 8),
                _buildSectionHeader('SYSTEM'),
                _buildSideNavTile(ref, 9, Icons.notifications_rounded, 'Notifications', activeTab, badgeCount: 5),
                _buildSideNavTile(ref, 10, Icons.article_rounded, 'Health Content', activeTab),
                _buildSideNavTile(ref, 11, Icons.feedback_rounded, 'Feedback', activeTab, badgeCount: 12),
                _buildSideNavTile(ref, 12, Icons.settings_rounded, 'Settings', activeTab),
                _buildSideNavTile(ref, 13, Icons.backup_rounded, 'Backup', activeTab),
                _buildSideNavTile(ref, 14, Icons.person_rounded, 'Profile', activeTab),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildSideLogoutTile(ref),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.neutralLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSideNavTile(WidgetRef ref, int index, IconData icon, String label, int currentIndex, {int badgeCount = 0}) {
    final isSelected = currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        selected: isSelected,
        selectedTileColor: AppTheme.primarySurface,
        selectedColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
        leading: Icon(icon, size: 20, color: isSelected ? AppTheme.primaryColor : AppTheme.neutralMedium),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
            color: isSelected ? AppTheme.primaryColor : AppTheme.neutralDark,
          ),
        ),
        trailing: badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
        onTap: () => ref.read(adminActiveTabProvider.notifier).setTab(index),
      ),
    );
  }

  Widget _buildSideLogoutTile(WidgetRef ref) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
          leading: const Icon(Icons.logout_rounded, color: AppTheme.errorColor, size: 20),
          title: const Text(
            'Log Out',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.errorColor),
          ),
          onTap: () => _showLogoutConfirmation(context, ref),
        ),
      ),
    );
  }

  // ── Drawer (Mobile) ────────────────────────────────────────────────────────

  Widget _buildDrawer(
    BuildContext context,
    WidgetRef ref,
    int activeTab,
    String adminName,
    String adminEmail,
  ) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Gradient Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: Container(
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.shield_rounded, color: AppTheme.primaryColor, size: 42),
            ),
            accountName: Text(
              adminName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              adminEmail,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerSectionHeader('MAIN'),
                _buildDrawerTile(context, ref, index: 0, icon: Icons.dashboard_rounded, label: 'Dashboard', currentIndex: activeTab),
                _buildDrawerTile(context, ref, index: 1, icon: Icons.verified_user_rounded, label: 'Doctor Verification', currentIndex: activeTab),
                _buildDrawerTile(context, ref, index: 2, icon: Icons.people_rounded, label: 'Users', currentIndex: activeTab),
                _buildDrawerTile(context, ref, index: 3, icon: Icons.calendar_month_rounded, label: 'Appointments', currentIndex: activeTab),

                _buildDrawerSectionHeader('MONITORING'),
                _buildDrawerTile(context, ref, index: 4, icon: Icons.video_call_rounded, label: 'Consultations', currentIndex: activeTab),
                _buildDrawerTile(context, ref, index: 5, icon: Icons.bar_chart_rounded, label: 'Analytics', currentIndex: activeTab),
                _buildDrawerTile(context, ref, index: 6, icon: Icons.assessment_rounded, label: 'Reports', currentIndex: activeTab),
                _buildDrawerTile(context, ref, index: 7, icon: Icons.security_rounded, label: 'Security Center', currentIndex: activeTab, badgeCount: 3),
                _buildDrawerTile(context, ref, index: 8, icon: Icons.history_rounded, label: 'Audit Logs', currentIndex: activeTab),

                _buildDrawerSectionHeader('SYSTEM'),
                _buildDrawerTile(context, ref, index: 9, icon: Icons.notifications_rounded, label: 'Notifications', currentIndex: activeTab, badgeCount: 5),
                _buildDrawerTile(context, ref, index: 10, icon: Icons.article_rounded, label: 'Health Content', currentIndex: activeTab),
                _buildDrawerTile(context, ref, index: 11, icon: Icons.feedback_rounded, label: 'Feedback & Complaints', currentIndex: activeTab, badgeCount: 12),
                _buildDrawerTile(context, ref, index: 12, icon: Icons.settings_rounded, label: 'Settings', currentIndex: activeTab),
                _buildDrawerTile(context, ref, index: 13, icon: Icons.backup_rounded, label: 'Backup & Recovery', currentIndex: activeTab),
                _buildDrawerTile(context, ref, index: 14, icon: Icons.person_rounded, label: 'Admin Profile', currentIndex: activeTab),
              ],
            ),
          ),
          const Divider(),
          _buildLogoutTile(context, ref),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDrawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.neutralLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context,
    WidgetRef ref, {
    required int index,
    required IconData icon,
    required String label,
    required int currentIndex,
    int badgeCount = 0,
  }) {
    final isSelected = currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: AppTheme.primarySurface,
        selectedColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        leading: Icon(icon, color: isSelected ? AppTheme.primaryColor : AppTheme.neutralMedium),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
            color: isSelected ? AppTheme.primaryColor : AppTheme.neutralDark,
          ),
        ),
        trailing: badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
        onTap: () {
          ref.read(adminActiveTabProvider.notifier).setTab(index);
          Navigator.pop(context); // Close Drawer
        },
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        leading: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
        title: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.errorColor),
        ),
        onTap: () {
          Navigator.pop(context); // Close Drawer
          _showLogoutConfirmation(context, ref);
        },
      ),
    );
  }

  // ── Shared ─────────────────────────────────────────────────────────────────

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out Session?'),
        content: const Text('Are you sure you want to terminate your TeleCare admin session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle(int tab) {
    switch (tab) {
      case 0: return 'Admin Dashboard';
      case 1: return 'Practitioner Verifications';
      case 2: return 'User Accounts';
      case 3: return 'Appointments Log';
      case 4: return 'Consultation Monitoring';
      case 5: return 'System Analytics';
      case 6: return 'System Reports';
      case 7: return 'Security Center';
      case 8: return 'Security Audit Logs';
      case 9: return 'Notifications';
      case 10: return 'Health Content';
      case 11: return 'Feedback & Complaints';
      case 12: return 'Admin Settings';
      case 13: return 'Backup & Recovery';
      case 14: return 'Admin Profile';
      default: return 'TeleCare Admin';
    }
  }

  Widget _buildBody(int tab) {
    switch (tab) {
      case 0: return const DashboardView();
      case 1: return const DoctorVerificationView();
      case 2: return const user_views.UserManagementView();
      case 3: return const AppointmentManagementView();
      case 4: return const ConsultationMonitoringView();
      case 5: return const AnalyticsView();
      case 6: return const ReportsView();
      case 7: return const SecurityCenterView();
      case 8: return const AuditLogsView();
      case 9: return const NotificationsView();
      case 10: return const HealthContentView();
      case 11: return const FeedbackComplaintsView();
      case 12: return const SettingsView();
      case 13: return const BackupRecoveryView();
      case 14: return const AdminProfileView();
      default: return const DashboardView();
    }
  }
}
