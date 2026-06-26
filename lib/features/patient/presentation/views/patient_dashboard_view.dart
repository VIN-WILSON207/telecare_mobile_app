import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../appointments/providers/appointments_providers.dart';
import '../../../../core/theme/app_theme.dart';

class PatientDashboardView extends ConsumerWidget {
  final UserModel user;

  const PatientDashboardView({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(patientAppointmentsProvider(user.uid));
    final doctorsAsync = ref.watch(verifiedDoctorsProvider);

    final upcomingAppointment = appointmentsAsync.maybeWhen(
      data: (list) {
        final approved = list.where((a) =>
            a.status.toLowerCase() == 'approved' &&
            a.appointmentDate.isAfter(DateTime.now().subtract(const Duration(hours: 1))));
        return approved.isNotEmpty ? approved.first : null;
      },
      orElse: () => null,
    );

    final firstName = user.fullName.split(' ').first;

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        ref.invalidate(patientAppointmentsProvider(user.uid));
        ref.invalidate(verifiedDoctorsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting & Overall Health Score
            Text(
              'Hello, $firstName 👋',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              'How are you feeling today?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Health Score card (from React design)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Health Score',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: const [
                      Text(
                        '87',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ' /100',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Icon(Icons.trending_up, color: AppTheme.successColor, size: 16),
                      SizedBox(width: 6),
                      Text(
                        '+4 points this week',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vitals Grid (design requirement)
            Text(
              'Vitals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: const [
                _VitalCard(
                  icon: Icons.favorite_rounded,
                  label: 'Heart Rate',
                  value: '72',
                  unit: 'bpm',
                  color: Color(0xFFFF4D6A),
                  trend: '↑ 2%',
                ),
                _VitalCard(
                  icon: Icons.speed_rounded,
                  label: 'Blood Pressure',
                  value: '118/76',
                  unit: 'mmHg',
                  color: Color(0xFF4A90E2),
                ),
                _VitalCard(
                  icon: Icons.water_drop_rounded,
                  label: 'Blood Glucose',
                  value: '94',
                  unit: 'mg/dL',
                  color: Color(0xFFA78BFA),
                  trend: '↓ 3%',
                ),
                _VitalCard(
                  icon: Icons.thermostat_rounded,
                  label: 'Temperature',
                  value: '98.4',
                  unit: '°F',
                  color: Color(0xFFF59E0B),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Notifications (from healthcare telemedicine design)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (_buildNotifications(appointmentsAsync).any((n) => !n.isRead))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_buildNotifications(appointmentsAsync).where((n) => !n.isRead).length} new',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ..._buildNotifications(appointmentsAsync).take(3).map((notification) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: notification.isRead ? AppTheme.cardWhite : AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: notification.isRead
                        ? const Color(0xFFE2E8F0)
                        : AppTheme.primaryColor.withValues(alpha: 0.25),
                  ),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: notification.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(notification.icon, color: notification.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
                                    color: AppTheme.neutralDark,
                                  ),
                                ),
                              ),
                              if (!notification.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.neutralMedium,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.time,
                            style: const TextStyle(fontSize: 10, color: AppTheme.neutralLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 28),

            // Upcoming Approved Appointment (if any)
            if (upcomingAppointment != null) ...[
              Text(
                'Upcoming Appointment',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primarySurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.videocam_rounded, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. ${upcomingAppointment.doctorName}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.neutralDark,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${upcomingAppointment.reason} · Video Call',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, color: AppTheme.primaryColor, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                _formatShortDateTime(upcomingAppointment.appointmentDate),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => context.go('/consultations'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Join', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Quick Book Appointment Highlight Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_task_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need a Consultant?',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryDark,
                              ),
                        ),
                        Text(
                          'Instantly schedule a virtual session',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => context.go('/appointments'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Recent/Active Doctors list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Doctors',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                TextButton(
                  onPressed: () => context.go('/appointments'),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            doctorsAsync.when(
              data: (doctors) {
                if (doctors.isEmpty) {
                  return const _InfoBox(message: 'No verified doctors available.');
                }
                final recent = doctors.take(3).toList();
                return Column(
                  children: recent.map((doctor) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primarySurface,
                            backgroundImage: doctor.profileImage != null && doctor.profileImage!.isNotEmpty
                                ? NetworkImage(doctor.profileImage!)
                                : null,
                            child: doctor.profileImage == null || doctor.profileImage!.isEmpty
                                ? const Icon(Icons.person, color: AppTheme.primaryColor)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dr. ${doctor.fullName}',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.neutralDark,
                                      ),
                                ),
                                Row(
                                  children: const [
                                    Icon(Icons.verified_rounded, color: AppTheme.primaryColor, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Active Now',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => context.go('/appointments'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primarySurface,
                              foregroundColor: AppTheme.primaryColor,
                              elevation: 0,
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _InfoBox(message: 'Error loading doctors: $e'),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatShortDateTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'Today, $h:$m · ${months[d.month - 1]} ${d.day}';
  }

  static List<_HomeNotification> _buildNotifications(AsyncValue appointmentsAsync) {
    final notifications = <_HomeNotification>[
      _HomeNotification(
        title: 'Health Tip',
        message: 'Your resting heart rate trend is improving. Keep up the good work!',
        time: 'Yesterday',
        icon: Icons.favorite_rounded,
        color: const Color(0xFFFF4D6A),
        isRead: true,
      ),
      _HomeNotification(
        title: 'Prescription Ready',
        message: 'Your latest prescription has been updated by your care team.',
        time: '1 hr ago',
        icon: Icons.medication_rounded,
        color: AppTheme.accentAlt,
        isRead: false,
      ),
    ];

    appointmentsAsync.maybeWhen(
      data: (list) {
        final pending = list.where((a) => a.status.toLowerCase() == 'pending').length;
        final approved = list.where((a) =>
            a.status.toLowerCase() == 'approved' &&
            a.appointmentDate.isAfter(DateTime.now().subtract(const Duration(hours: 1)))).length;

        if (pending > 0) {
          notifications.insert(
            0,
            _HomeNotification(
              title: 'Appointment Request Sent',
              message: 'You have $pending pending request${pending != 1 ? 's' : ''} awaiting doctor review.',
              time: 'Just now',
              icon: Icons.calendar_today_rounded,
              color: AppTheme.warningColor,
              isRead: false,
            ),
          );
        }
        if (approved > 0) {
          notifications.insert(
            0,
            _HomeNotification(
              title: 'Appointment Reminder',
              message: 'You have an approved consultation coming up. Tap Join when it is time.',
              time: '2 min ago',
              icon: Icons.notifications_active_rounded,
              color: AppTheme.primaryColor,
              isRead: false,
            ),
          );
        }
      },
      orElse: () {},
    );

    return notifications;
  }
}

class _HomeNotification {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  final bool isRead;

  _HomeNotification({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    required this.isRead,
  });
}

class _VitalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final String? trend;

  const _VitalCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              if (trend != null)
                Text(
                  trend!,
                  style: const TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.neutralDark,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.neutralLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.neutralMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String message;
  const _InfoBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutralSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}
