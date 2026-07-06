import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/presentation/telecare_home_chrome.dart';
import '../../../appointments/data/models/appointment_model.dart';
import '../../../appointments/providers/appointments_providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/providers/auth_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorDashboardView extends ConsumerWidget {
  const DoctorDashboardView({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider(user.uid));
    final appointments = appointmentsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => const <AppointmentModel>[],
    );
    final stats = _DoctorStats.fromAppointments(appointments);
    final todaySchedule = _todayAppointments(appointments);
    final greeting = _timeBasedGreeting();
    final displayName = _displayName(user);
    final upcomingReminder = _upcomingApprovedAppointment(appointments);

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        ref.invalidate(doctorAppointmentsProvider(user.uid));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, $displayName',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: user.isOnline == true ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.isOnline == true ? 'Active Consultation' : 'Offline / Away',
                            style: TextStyle(
                              color: user.isOnline == true ? Colors.green.shade700 : AppTheme.neutralMedium,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: user.isOnline == true,
                            activeThumbColor: AppTheme.primaryColor,
                            onChanged: (val) async {
                              try {
                                final firestore = ref.read(firestoreProvider);
                                await firestore
                                    .collection('users')
                                    .doc(user.uid)
                                    .update({'isOnline': val});
                                
                                // Refresh AuthNotifier state
                                final updatedProfile = await ref.read(authRepositoryProvider).getUserProfile(user.uid);
                                if (updatedProfile != null) {
                                  ref.read(authNotifierProvider.notifier).updateAuthenticatedUser(updatedProfile);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to update status: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const TrustBadge(
                        label: 'Verified',
                        icon: Icons.verified_rounded,
                      ),
                    ],
                  ),
                ),
                const TrustBadge(
                  label: 'Encrypted',
                  icon: Icons.lock_rounded,
                  color: AppTheme.protectedColor,
                  backgroundColor: AppTheme.primarySurface,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (upcomingReminder != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upcoming Consultation',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Appointment with ${upcomingReminder.patientName} starts in ${upcomingReminder.appointmentDate.difference(DateTime.now()).inMinutes} minutes.',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => launchCall(context, ref, upcomingReminder),
                      child: const Text('Join Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
            _SearchPatientField(onTap: () => context.go('/patients')),
            const SizedBox(height: 24),
            _SectionHeader(
              title: "Today's Schedule",
              actionLabel: 'View All',
              onAction: () => context.go('/appointments'),
            ),
            const SizedBox(height: 12),
            appointmentsAsync.when(
              data: (_) => _TodayScheduleList(appointments: todaySchedule),
              loading: () => const _LoadingBox(),
              error: (e, _) => _InfoBox(message: 'Unable to load schedule: $e'),
            ),
            const SizedBox(height: 18),
            const _WeekCalendarStrip(),
            const SizedBox(height: 26),
            _SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: 12),
            const _DoctorQuickActions(),
            const SizedBox(height: 26),
            _SectionHeader(title: 'Pending Tasks'),
            const SizedBox(height: 12),
            _PendingTasks(stats: stats),
            const SizedBox(height: 26),
            _SectionHeader(title: 'Recent Patients'),
            const SizedBox(height: 12),
            _RecentPatients(appointments: appointments),
            const SizedBox(height: 26),
            _SectionHeader(title: 'Analytics'),
            const SizedBox(height: 12),
            _AnalyticsGrid(stats: stats),
            const SizedBox(height: 26),
            const _SecureCareCard(),
          ],
        ),
      ),
    );
  }

  static List<AppointmentModel> _todayAppointments(
    List<AppointmentModel> appointments,
  ) {
    final now = DateTime.now();
    final list =
        appointments
            .where(
              (appointment) {
                final isToday = appointment.appointmentDate.year == now.year &&
                    appointment.appointmentDate.month == now.month &&
                    appointment.appointmentDate.day == now.day;
                if (!isToday) return false;

                final status = appointment.status.toLowerCase();
                if (status == 'completed' || status == 'cancelled' || status == 'rejected') {
                  return false;
                }

                return appointment.appointmentDate.isAfter(now);
              },
            )
            .toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    return list;
  }

  String _displayName(UserModel user) {
    final prefix = user.prefix ?? user.role.displayPrefix;
    final trimmed = user.fullName.trim();
    if (trimmed.isEmpty) return user.role.label;
    final firstName = trimmed.split(RegExp(r'\s+')).first;
    return prefix.isNotEmpty ? '$prefix $firstName' : firstName;
  }

  static AppointmentModel? _upcomingApprovedAppointment(List<AppointmentModel> appointments) {
    final now = DateTime.now();
    for (final a in appointments) {
      if (a.status.toLowerCase() == 'approved') {
        final diff = a.appointmentDate.difference(now);
        if (diff.inMinutes >= 0 && diff.inMinutes <= 30) {
          return a;
        }
      }
    }
    return null;
  }

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _SearchPatientField extends StatelessWidget {
  const _SearchPatientField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      onTap: onTap,
      style: const TextStyle(color: Colors.black, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search patient...',
        hintStyle: const TextStyle(color: Colors.black54),
        suffixIcon: const Icon(Icons.search_rounded, color: Colors.black87),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}

class _TodayScheduleList extends ConsumerWidget {
  const _TodayScheduleList({required this.appointments});

  final List<AppointmentModel> appointments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (appointments.isEmpty) {
      return const _InfoBox(message: 'No appointments scheduled for today.');
    }

    return Column(
      children: [
        for (final appointment in appointments.take(4))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SurfaceCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 58,
                    child: Text(
                      _formatTime(appointment.appointmentDate),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              appointment.reason.toLowerCase().contains(
                                    'clinic',
                                  )
                                  ? Icons.local_hospital_rounded
                                  : Icons.videocam_rounded,
                              size: 15,
                              color: AppTheme.neutralMedium,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                appointment.reason.toLowerCase().contains(
                                      'clinic',
                                    )
                                    ? 'Clinic'
                                    : 'Video',
                                style: const TextStyle(
                                  color: AppTheme.neutralMedium,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => launchCall(context, ref, appointment),
                    icon: const Icon(
                      Icons.video_call_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    tooltip: 'Start consultation',
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _WeekCalendarStrip extends StatelessWidget {
  const _WeekCalendarStrip();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (index) => start.add(Duration(days: index)));

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          final isToday =
              day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;
          return Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isToday ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weekdayLabel(day.weekday),
                  style: TextStyle(
                    color: isToday ? Colors.white : AppTheme.neutralMedium,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isToday ? Colors.white : Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DoctorQuickActions extends StatelessWidget {
  const _DoctorQuickActions();

  @override
  Widget build(BuildContext context) {
    final items = [
      _ActionItem(
        'Start Consultation',
        Icons.play_arrow_rounded,
        () => context.go('/consultations'),
      ),
      _ActionItem(
        'Schedule',
        Icons.calendar_month_rounded,
        () => context.go('/appointments'),
      ),
      _ActionItem(
        'Write Prescription',
        Icons.description_rounded,
        () => context.go('/medical-records'),
      ),
      _ActionItem(
        'Patient Records',
        Icons.folder_shared_rounded,
        () => context.go('/medical-records'),
      ),
      _ActionItem(
        'Requests',
        Icons.assignment_rounded,
        () => context.go('/appointments'),
      ),
      _ActionItem(
        'Safety Measures',
        Icons.health_and_safety_rounded,
        () => context.go('/upload-safety'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.55,
      ),
      itemBuilder: (context, index) => _ActionTile(item: items[index]),
    );
  }
}

class _PendingTasks extends StatelessWidget {
  const _PendingTasks({required this.stats});

  final _DoctorStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _TaskItem('Prescription Requests', 5, AppTheme.alertColor),
      _TaskItem('Verification Requests', 2, AppTheme.infoColor),
      _TaskItem('Unread Messages', 3, AppTheme.errorColor),
      _TaskItem('Patient Requests', stats.pending, AppTheme.alertColor),
    ];

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SurfaceCard(
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${item.count}',
                        style: TextStyle(
                          color: item.color,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentPatients extends StatelessWidget {
  const _RecentPatients({required this.appointments});

  final List<AppointmentModel> appointments;

  @override
  Widget build(BuildContext context) {
    final recent = <String, AppointmentModel>{};
    for (final appointment in appointments) {
      recent.putIfAbsent(appointment.patientId, () => appointment);
    }

    if (recent.isEmpty) {
      return const _InfoBox(
        message: 'Recent patients will appear after consultations.',
      );
    }

    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recent.values.take(6).length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final appointment = recent.values.elementAt(index);
          return Container(
            width: 210,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppTheme.primarySurface,
                      child: Icon(
                        Icons.person_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        appointment.patientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const TrustBadge(
                  label: 'Protected',
                  icon: Icons.lock_rounded,
                  color: AppTheme.protectedColor,
                  backgroundColor: AppTheme.primarySurface,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AnalyticsGrid extends StatelessWidget {
  const _AnalyticsGrid({required this.stats});

  final _DoctorStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _AnalyticsItem("Today's Patients", stats.today, AppTheme.infoColor),
      _AnalyticsItem('Completed', stats.completed, AppTheme.successColor),
      _AnalyticsItem('Upcoming', stats.upcoming, AppTheme.primaryColor),
      _AnalyticsItem('Pending', stats.pending, AppTheme.alertColor),
      _AnalyticsItem('Cancelled', stats.cancelled, AppTheme.errorColor),
      _AnalyticsItem('Unread Chats', 3, AppTheme.errorColor),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) => _AnalyticsCard(item: items[index]),
    );
  }
}

class _SecureCareCard extends StatelessWidget {
  const _SecureCareCard();

  @override
  Widget build(BuildContext context) {
    return const _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrustBadge(
            label: 'End-to-end encrypted messaging and video consultations',
            icon: Icons.lock_rounded,
            color: AppTheme.protectedColor,
            backgroundColor: AppTheme.primarySurface,
            maxWidth: 320,
          ),
          SizedBox(height: 10),
          Text(
            'Secure cloud medical records, verified doctor status, one-tap video consultations, and digital prescriptions are enabled for trusted care delivery.',
            style: TextStyle(
              color: AppTheme.neutralMedium,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.item});

  final _ActionItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(item.icon, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.item});

  final _AnalyticsItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_rounded, color: item.color, size: 20),
          const Spacer(),
          Text(
            '${item.value}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.neutralMedium, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Text(
        message,
        style: const TextStyle(color: Colors.black, fontSize: 13, height: 1.4),
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return const _SurfaceCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _DoctorStats {
  const _DoctorStats({
    required this.today,
    required this.completed,
    required this.pending,
    required this.cancelled,
    required this.upcoming,
  });

  factory _DoctorStats.fromAppointments(List<AppointmentModel> appointments) {
    final now = DateTime.now();
    final today = appointments
        .where(
          (appointment) =>
              appointment.appointmentDate.year == now.year &&
              appointment.appointmentDate.month == now.month &&
              appointment.appointmentDate.day == now.day,
        )
        .length;
    return _DoctorStats(
      today: today,
      completed: appointments
          .where((a) => a.status.toLowerCase() == 'completed')
          .length,
      pending: appointments
          .where((a) => a.status.toLowerCase() == 'pending')
          .length,
      cancelled: appointments
          .where((a) => a.status.toLowerCase() == 'cancelled')
          .length,
      upcoming: appointments
          .where((a) => a.appointmentDate.isAfter(now))
          .length,
    );
  }

  final int today;
  final int completed;
  final int pending;
  final int cancelled;
  final int upcoming;
}

class _ActionItem {
  const _ActionItem(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _TaskItem {
  const _TaskItem(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;
}

class _AnalyticsItem {
  const _AnalyticsItem(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _weekdayLabel(int weekday) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return labels[weekday - 1];
}

Future<void> launchCall(BuildContext context, WidgetRef ref, AppointmentModel appointment) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('consultations')
        .where('appointmentId', isEqualTo: appointment.id)
        .where('doctorId', isEqualTo: appointment.doctorId)
        .get();

    String consultationId;
    if (snapshot.docs.isNotEmpty) {
      consultationId = snapshot.docs.first.id;
    } else {
      final docRef = await firestore.collection('consultations').add({
        'appointmentId': appointment.id,
        'doctorId': appointment.doctorId,
        'patientId': appointment.patientId,
        'roomId': appointment.id,
        'status': 'scheduled',
        'mode': 'video',
        'startedAt': null,
        'endedAt': null,
        'duration': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      consultationId = docRef.id;
    }

    if (context.mounted) {
      context.go('/consultation/$consultationId');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to launch call: $e')),
      );
    }
  }
}
