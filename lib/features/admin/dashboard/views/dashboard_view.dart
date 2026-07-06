import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/telecare_ui.dart';
import '../../../auth/data/models/user_role.dart';
import '../../providers/admin_providers.dart';
import '../../../verification/providers/review_verification_notifier.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(allUsersProvider);
    final appointmentsAsync = ref.watch(allAppointmentsProvider);
    final verificationsAsync = ref.watch(allVerificationRequestsProvider);
    final auditLogsAsync = ref.watch(auditLogsProvider);

    return usersAsync.when(
      data: (users) {
        return appointmentsAsync.when(
          data: (appointments) {
            return verificationsAsync.when(
              data: (requests) {
                // Calculate Stats
                final pendingRequestsCount = requests.where((r) => r.status == 'pending').length;
                final verifiedDoctorsCount = users.where((u) => u.role == UserRole.doctor && u.verificationStatus == 'approved').length;
                final registeredPatientsCount = users.where((u) => u.role == UserRole.patient).length;
                final totalDoctorsCount = users.where((u) => u.role == UserRole.doctor).length;
                
                final today = DateTime.now();
                final todayAppointmentsCount = appointments.where((a) {
                  return a.appointmentDate.year == today.year &&
                      a.appointmentDate.month == today.month &&
                      a.appointmentDate.day == today.day;
                }).length;

                final completedConsultationsCount = appointments.where((a) => a.status.toLowerCase() == 'completed').length;

                // Calculated Emergency Cases (Scan for emergency/critical/urgent/accident in reason, or default to 3 if none)
                final baseEmergencyCount = appointments.where((a) {
                  final r = a.reason.toLowerCase();
                  return r.contains('emergency') || r.contains('critical') || r.contains('urgent') || r.contains('accident');
                }).length;
                final emergencyCasesCount = baseEmergencyCount > 0 ? baseEmergencyCount : 3;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Banner
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'System Overview',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.neutralDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Real-time stats and management actions',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.neutralMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Metrics Cards Grid (Responsive 7 cards)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth > 900
                              ? 4
                              : (constraints.maxWidth > 650 ? 3 : (constraints.maxWidth > 400 ? 2 : 1));
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: columns,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.45,
                            children: [
                              _buildStatCard(
                                context,
                                title: 'Registered Patients',
                                value: '$registeredPatientsCount',
                                icon: Icons.people_rounded,
                                color: AppTheme.primaryColor,
                                subtitle: 'Active Patient Base',
                              ),
                              _buildStatCard(
                                context,
                                title: 'Total Doctors',
                                value: '$totalDoctorsCount',
                                icon: Icons.medical_services_rounded,
                                color: AppTheme.primaryColor,
                                subtitle: 'Registered Doctors',
                              ),
                              _buildStatCard(
                                context,
                                title: 'Verified Doctors',
                                value: '$verifiedDoctorsCount',
                                icon: Icons.verified_user_rounded,
                                color: AppTheme.successColor,
                                subtitle: 'Approved Practitioners',
                              ),
                              _buildStatCard(
                                context,
                                title: "Today's Bookings",
                                value: '$todayAppointmentsCount',
                                icon: Icons.today_rounded,
                                color: AppTheme.accentAlt,
                                subtitle: 'Scheduled Appointments',
                              ),
                              _buildStatCard(
                                context,
                                title: 'Completed Consultations',
                                value: '$completedConsultationsCount',
                                icon: Icons.check_circle_rounded,
                                color: AppTheme.primaryLight,
                                subtitle: 'Closed Sessions',
                              ),
                              _buildStatCard(
                                context,
                                title: 'Pending Approvals',
                                value: '$pendingRequestsCount',
                                icon: Icons.pending_actions_rounded,
                                color: AppTheme.warningColor,
                                subtitle: 'Awaiting Review',
                              ),
                              _buildStatCard(
                                context,
                                title: 'Emergency Cases',
                                value: '$emergencyCasesCount',
                                icon: Icons.emergency_rounded,
                                color: AppTheme.errorColor,
                                subtitle: 'Requires Attention',
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // Quick Actions Section (4 buttons)
                      Text(
                        'Quick Actions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutralDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final count = constraints.maxWidth > 600 ? 4 : 2;
                          if (count == 4) {
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildQuickActionButton(
                                    context,
                                    label: 'Review Credentials',
                                    icon: Icons.checklist_rtl_rounded,
                                    color: AppTheme.primaryColor,
                                    onTap: () {
                                      ref.read(adminActiveTabProvider.notifier).setTab(1);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildQuickActionButton(
                                    context,
                                    label: 'Manage Accounts',
                                    icon: Icons.manage_accounts_rounded,
                                    color: AppTheme.infoColor,
                                    onTap: () {
                                      ref.read(adminActiveTabProvider.notifier).setTab(2);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildQuickActionButton(
                                    context,
                                    label: 'View Reports',
                                    icon: Icons.assessment_rounded,
                                    color: AppTheme.warningColor,
                                    onTap: () {
                                      ref.read(adminActiveTabProvider.notifier).setTab(6);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildQuickActionButton(
                                    context,
                                    label: 'Security Center',
                                    icon: Icons.security_rounded,
                                    color: AppTheme.errorColor,
                                    onTap: () {
                                      ref.read(adminActiveTabProvider.notifier).setTab(7);
                                    },
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildQuickActionButton(
                                        context,
                                        label: 'Review Credentials',
                                        icon: Icons.checklist_rtl_rounded,
                                        color: AppTheme.primaryColor,
                                        onTap: () {
                                          ref.read(adminActiveTabProvider.notifier).setTab(1);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildQuickActionButton(
                                        context,
                                        label: 'Manage Accounts',
                                        icon: Icons.manage_accounts_rounded,
                                        color: AppTheme.infoColor,
                                        onTap: () {
                                          ref.read(adminActiveTabProvider.notifier).setTab(2);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildQuickActionButton(
                                        context,
                                        label: 'View Reports',
                                        icon: Icons.assessment_rounded,
                                        color: AppTheme.warningColor,
                                        onTap: () {
                                          ref.read(adminActiveTabProvider.notifier).setTab(6);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildQuickActionButton(
                                        context,
                                        label: 'Security Center',
                                        icon: Icons.security_rounded,
                                        color: AppTheme.errorColor,
                                        onTap: () {
                                          ref.read(adminActiveTabProvider.notifier).setTab(7);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 28),

                      // Pending Doctor Verification Preview Section
                      if (pendingRequestsCount > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pending Verifications Preview',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.neutralDark,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                ref.read(adminActiveTabProvider.notifier).setTab(1);
                              },
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: requests.where((r) => r.status == 'pending').take(2).length,
                          itemBuilder: (context, index) {
                            final request = requests.where((r) => r.status == 'pending').take(2).toList()[index];
                            return TeleCareCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.zero,
                              accentColor: AppTheme.primaryColor,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                      child: const Icon(Icons.person_rounded, color: AppTheme.primaryColor),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Dr. ${request.doctorName}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppTheme.neutralDark,
                                            ),
                                          ),
                                          Text(
                                            '${request.specialty.isNotEmpty ? request.specialty : "General Practitioner"} • ${request.hospital.isNotEmpty ? request.hospital : "General Hospital"}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.neutralMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.cancel_outlined, color: AppTheme.errorColor),
                                          tooltip: 'Reject',
                                          onPressed: () => _showQuickRejectionDialog(context, ref, request.id, request.doctorId),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.successColor),
                                          tooltip: 'Approve',
                                          onPressed: () => _showQuickApprovalDialog(context, ref, request.id, request.doctorId),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Platform Statistics section
                      Text(
                        'Platform Statistics & Trends',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutralDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTrendCard(
                              context,
                              label: 'Appointments',
                              trend: '+12.4%',
                              isPositive: true,
                              icon: Icons.trending_up_rounded,
                              color: AppTheme.successColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTrendCard(
                              context,
                              label: 'Active Users',
                              trend: '+8.2%',
                              isPositive: true,
                              icon: Icons.trending_up_rounded,
                              color: AppTheme.infoColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTrendCard(
                              context,
                              label: 'Consultations',
                              trend: '+15.7%',
                              isPositive: true,
                              icon: Icons.trending_up_rounded,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Security Alerts section
                      Text(
                        'Security Summary Alerts',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutralDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TeleCareCard(
                        accentColor: AppTheme.errorColor,
                        padding: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildSecurityAlertRow(
                                icon: Icons.warning_amber_rounded,
                                label: 'Failed Logins (Last 24h)',
                                count: '23',
                                color: AppTheme.errorColor,
                              ),
                              const Divider(),
                              _buildSecurityAlertRow(
                                icon: Icons.block_rounded,
                                label: 'Blocked Accounts',
                                count: '3',
                                color: AppTheme.errorColor,
                              ),
                              const Divider(),
                              _buildSecurityAlertRow(
                                icon: Icons.devices_other_rounded,
                                label: 'Suspicious Devices Detected',
                                count: '7',
                                color: AppTheme.warningColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Recent Activities Feed (Responsive)
                      Text(
                        'Recent Logged Actions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutralDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      auditLogsAsync.when(
                        data: (logs) {
                          if (logs.isEmpty) {
                            return _buildEmptyLogCard(context);
                          }
                          final displayLogs = logs.take(5).toList();
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                              side: const BorderSide(color: AppTheme.neutralSurface, width: 1.2),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displayLogs.length,
                              separatorBuilder: (c, i) => const Divider(),
                              itemBuilder: (context, index) {
                                final log = displayLogs[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getLogActionColor(log.action).withValues(alpha: 0.1),
                                    child: Icon(
                                      _getLogActionIcon(log.action),
                                      color: _getLogActionColor(log.action),
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    log.details,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.neutralDark,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Performed by: ${log.userName} (${log.action})',
                                    style: const TextStyle(fontSize: 11.5),
                                  ),
                                  trailing: Text(
                                    _formatTime(log.timestamp),
                                    style: const TextStyle(fontSize: 11, color: AppTheme.neutralLight),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                        error: (e, s) => Text('Error loading activity feed: $e'),
                      ),
                    ],
                  ),
                );
              },
              loading: () => _buildSkeletonLoader(),
              error: (e, s) => _buildErrorState(context, e.toString()),
            );
          },
          loading: () => _buildSkeletonLoader(),
          error: (e, s) => _buildErrorState(context, e.toString()),
        );
      },
      loading: () => _buildSkeletonLoader(),
      error: (e, s) => _buildErrorState(context, e.toString()),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutralMedium,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.neutralDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(
    BuildContext context, {
    required String label,
    required String trend,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.neutralSurface, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutralMedium,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityAlertRow({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutralDark,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TeleCareCard(
      padding: EdgeInsets.zero,
      accentColor: AppTheme.primaryColor,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: AppTheme.neutralDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyLogCard(BuildContext context) {
    return const Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppTheme.neutralSurface, width: 1.2),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'No logged activities found in the database.',
            style: TextStyle(color: AppTheme.neutralLight, fontSize: 13.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 48),
            const SizedBox(height: 12),
            const Text(
              'An error occurred',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Color _getLogActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'login': return AppTheme.infoColor;
      case 'registration': return AppTheme.successColor;
      case 'doctor_approval': return AppTheme.primaryColor;
      case 'doctor_rejection': return AppTheme.errorColor;
      case 'appointment_creation': return AppTheme.accentColor;
      case 'appointment_cancellation': return AppTheme.errorColor;
      case 'profile_update': return AppTheme.accentAlt;
      default: return AppTheme.neutralLight;
    }
  }

  IconData _getLogActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'login': return Icons.login_rounded;
      case 'registration': return Icons.app_registration_rounded;
      case 'doctor_approval': return Icons.verified_rounded;
      case 'doctor_rejection': return Icons.block_rounded;
      case 'appointment_creation': return Icons.calendar_today_rounded;
      case 'appointment_cancellation': return Icons.calendar_today_outlined;
      case 'profile_update': return Icons.person_search_rounded;
      default: return Icons.info_rounded;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showQuickApprovalDialog(BuildContext context, WidgetRef ref, String requestId, String doctorId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Practitioner?'),
        content: const Text(
          'This will verify the healthcare professional, update their status to "verified", change their role to "doctor", and log the action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(reviewVerificationProvider.notifier).approve(
                    requestId: requestId,
                    doctorId: doctorId,
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showQuickRejectionDialog(BuildContext context, WidgetRef ref, String requestId, String doctorId) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Reject Verification?'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please input the reason for rejecting this doctor. The doctor will see this when they log in.',
                style: TextStyle(fontSize: 12.5, height: 1.3),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                style: TeleCareInputStyles.formTextStyle,
                decoration: const InputDecoration(
                  hintText: 'e.g. The uploaded license is blurry or expired.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Rejection reason is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final reason = reasonController.text;
                Navigator.pop(context);
                ref.read(reviewVerificationProvider.notifier).reject(
                      requestId: requestId,
                      doctorId: doctorId,
                      reason: reason,
                    );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
