import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../appointments/providers/appointments_providers.dart';
import '../../../../core/theme/app_theme.dart';

class DoctorDashboardView extends ConsumerWidget {
  final UserModel user;

  const DoctorDashboardView({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider(user.uid));

    final pendingCount = appointmentsAsync.maybeWhen(
      data: (list) => list.where((a) => a.status.toLowerCase() == 'pending').length,
      orElse: () => 0,
    );
    final approvedCount = appointmentsAsync.maybeWhen(
      data: (list) => list.where((a) => a.status.toLowerCase() == 'approved').length,
      orElse: () => 0,
    );
    final totalCount = appointmentsAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    final todayAppointments = appointmentsAsync.maybeWhen(
      data: (list) {
        final now = DateTime.now();
        return list.where((a) =>
            a.status.toLowerCase() == 'approved' &&
            a.appointmentDate.year == now.year &&
            a.appointmentDate.month == now.month &&
            a.appointmentDate.day == now.day).toList();
      },
      orElse: () => <dynamic>[],
    );

    final firstName = user.fullName.split(' ').first;

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        ref.invalidate(doctorAppointmentsProvider(user.uid));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting & Verification
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Day, Dr. $firstName 👨‍⚕️',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'Manage your consultations',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.statusApproved,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.verified_rounded, color: AppTheme.statusApprovedText, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: AppTheme.statusApprovedText,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Statistics Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.pending_actions_rounded,
                    value: '$pendingCount',
                    label: 'Pending',
                    color: AppTheme.warningColor,
                    bgColor: const Color(0xFFFEF3C7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_rounded,
                    value: '$approvedCount',
                    label: 'Approved',
                    color: AppTheme.successColor,
                    bgColor: AppTheme.primarySurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.people_outline_rounded,
                    value: '$totalCount',
                    label: 'All Patients',
                    color: AppTheme.infoColor,
                    bgColor: const Color(0xFFDBEAFE),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pending Queue Banner
            if (pendingCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.warningColor.withValues(alpha: 0.15),
                      AppTheme.warningColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: AppTheme.warningColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$pendingCount Pending Request${pendingCount != 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const Text(
                            'Patients are waiting for your review',
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => context.go('/appointments'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warningColor,
                        foregroundColor: Colors.white,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Today's Agenda
            Text(
              'Today\'s Schedule',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            if (todayAppointments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.event_busy_rounded, size: 40, color: AppTheme.neutralLight),
                    SizedBox(height: 8),
                    Text(
                      'No consultations scheduled for today.',
                      style: TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: todayAppointments.map((a) {
                  final timeStr = '${a.appointmentDate.hour.toString().padLeft(2, "0")}:${a.appointmentDate.minute.toString().padLeft(2, "0")}';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            timeStr,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.patientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.neutralDark,
                                ),
                              ),
                              Text(
                                a.reason,
                                style: const TextStyle(fontSize: 12, color: AppTheme.neutralMedium),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.video_call_rounded, color: AppTheme.primaryColor, size: 28),
                          onPressed: () => context.go('/consultations'),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.neutralDark,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.neutralLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
