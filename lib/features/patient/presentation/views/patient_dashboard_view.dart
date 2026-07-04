import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../appointments/data/models/appointment_model.dart';
import '../../../appointments/providers/appointments_providers.dart';
import '../../../auth/data/models/user_model.dart';

class PatientDashboardView extends ConsumerWidget {
  const PatientDashboardView({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(patientAppointmentsProvider(user.uid));
    final doctorsAsync = ref.watch(verifiedDoctorsProvider);
    final nextAppointment = appointmentsAsync.maybeWhen(
      data: _nextAppointmentFrom,
      orElse: () => null,
    );
    final firstName = user.fullName.trim().isEmpty
        ? 'there'
        : user.fullName.trim().split(RegExp(r'\s+')).first;
    final greeting = _timeBasedGreeting();

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        ref.invalidate(patientAppointmentsProvider(user.uid));
        ref.invalidate(verifiedDoctorsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $firstName',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            const _SearchDoctorsField(),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Next Appointment'),
            const SizedBox(height: 12),
            _NextAppointmentCard(appointment: nextAppointment),
            const SizedBox(height: 26),
            _SectionHeader(title: 'Quick Services'),
            const SizedBox(height: 12),
            _QuickServicesGrid(
              onEmergency: () => _showEmergencyMessage(context),
            ),
            const SizedBox(height: 26),
            _SectionHeader(title: 'Health Summary'),
            const SizedBox(height: 12),
            const _HealthSummaryGrid(),
            const SizedBox(height: 26),
            _SectionHeader(
              title: 'Nearby Doctors',
              actionLabel: 'See All',
              onAction: () => context.go('/appointments'),
            ),
            const SizedBox(height: 12),
            doctorsAsync.when(
              data: (doctors) => _NearbyDoctorsSection(doctors: doctors),
              loading: () => const _LoadingLine(),
              error: (e, _) => _InfoBox(message: 'Unable to load doctors: $e'),
            ),
            const SizedBox(height: 26),
            _SectionHeader(title: 'Health Tips'),
            const SizedBox(height: 12),
            const _HealthTipsCarousel(),
            const SizedBox(height: 26),
            _SectionHeader(title: 'Medication Reminder'),
            const SizedBox(height: 12),
            const _MedicationReminderCard(),
            const SizedBox(height: 26),
            _SectionHeader(title: 'Notifications'),
            const SizedBox(height: 12),
            ..._buildNotifications(
              appointmentsAsync,
            ).map(_NotificationTile.new),
          ],
        ),
      ),
    );
  }

  static AppointmentModel? _nextAppointmentFrom(
    List<AppointmentModel> appointments,
  ) {
    final now = DateTime.now();
    final upcoming =
        appointments
            .where(
              (a) =>
                  a.status.toLowerCase() == 'approved' &&
                  a.appointmentDate.isAfter(
                    now.subtract(const Duration(hours: 1)),
                  ),
            )
            .toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  static String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static void _showEmergencyMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency SOS request started.')),
    );
  }

  static List<_HomeNotification> _buildNotifications(
    AsyncValue<List<AppointmentModel>> appointmentsAsync,
  ) {
    final notifications = <_HomeNotification>[
      const _HomeNotification(
        title: 'Doctor sent a prescription',
        message: 'Your latest prescription is ready in Medical Records.',
        time: '1 hr ago',
        icon: Icons.medication_rounded,
        color: AppTheme.accentAlt,
      ),
      const _HomeNotification(
        title: 'Lab result available',
        message: 'A new lab result has been added to your records.',
        time: 'Yesterday',
        icon: Icons.science_rounded,
        color: AppTheme.infoColor,
      ),
    ];

    appointmentsAsync.maybeWhen(
      data: (appointments) {
        if (appointments.any((a) => a.status.toLowerCase() == 'approved')) {
          notifications.insert(
            0,
            const _HomeNotification(
              title: 'Appointment confirmed',
              message: 'Your consultation is confirmed. Join when it is time.',
              time: 'Just now',
              icon: Icons.event_available_rounded,
              color: AppTheme.primaryColor,
            ),
          );
        }
      },
      orElse: () {},
    );

    return notifications;
  }
}

class _SearchDoctorsField extends ConsumerStatefulWidget {
  const _SearchDoctorsField();

  @override
  ConsumerState<_SearchDoctorsField> createState() =>
      _SearchDoctorsFieldState();
}

class _SearchDoctorsFieldState extends ConsumerState<_SearchDoctorsField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(verifiedDoctorsProvider);
    final query = _controller.text.trim().toLowerCase();

    return Column(
      children: [
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => context.go('/appointments'),
          style: const TextStyle(color: Colors.black, fontSize: 17),
          decoration: InputDecoration(
            hintText: 'Search doctors by name or specialty',
            hintStyle: const TextStyle(color: Colors.black54),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.black87),
              onPressed: () => context.go('/appointments'),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        if (query.isNotEmpty) ...[
          const SizedBox(height: 10),
          doctorsAsync.when(
            data: (doctors) {
              final matches = doctors
                  .where((doctor) {
                    final searchable = [
                      doctor.fullName,
                      doctor.email,
                      doctor.specialty ?? '',
                      doctor.hospital ?? '',
                    ].join(' ').toLowerCase();
                    return searchable.contains(query);
                  })
                  .take(4)
                  .toList();

              if (matches.isEmpty) {
                return const _InfoBox(
                  message: 'No healthcare professional matches that search.',
                );
              }

              return Column(
                children: matches.map((doctor) {
                  final specialty = doctor.specialty?.isNotEmpty == true
                      ? doctor.specialty!
                      : 'Healthcare Professional';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SurfaceCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.medical_services_rounded,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dr. ${doctor.fullName}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  specialty,
                                  style: const TextStyle(
                                    color: AppTheme.neutralMedium,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/appointments'),
                            child: const Text('Book'),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const _LoadingLine(),
            error: (error, _) => _InfoBox(message: 'Search failed: $error'),
          ),
        ],
      ],
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({required this.appointment});

  final AppointmentModel? appointment;

  @override
  Widget build(BuildContext context) {
    if (appointment == null) {
      return _InfoBox(
        message:
            'No upcoming appointment yet. Book a consultation to get started.',
        actionLabel: 'Book Appointment',
        onAction: () => context.go('/appointments'),
      );
    }

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primarySurface,
                child: Icon(
                  Icons.medical_services_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${appointment!.doctorName}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDateTime(appointment!.appointmentDate),
                      style: const TextStyle(
                        color: AppTheme.neutralMedium,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/consultations'),
              icon: const Icon(Icons.videocam_rounded, size: 18),
              label: const Text('Join Video Call'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickServicesGrid extends StatelessWidget {
  const _QuickServicesGrid({required this.onEmergency});

  final VoidCallback onEmergency;

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickService(
        'Book Appointment',
        Icons.calendar_month_rounded,
        () => context.go('/appointments'),
      ),
      _QuickService(
        'Join Consultation',
        Icons.video_call_rounded,
        () => context.go('/consultations'),
      ),
      _QuickService(
        'Chat',
        Icons.chat_bubble_rounded,
        () => context.go('/messages'),
      ),
      _QuickService(
        'Prescriptions',
        Icons.medication_rounded,
        () => context.go('/prescriptions'),
      ),
      _QuickService(
        'Lab Results',
        Icons.science_rounded,
        () => context.go('/medical-records'),
      ),
      _QuickService(
        'Emergency',
        Icons.emergency_rounded,
        onEmergency,
        isEmergency: true,
      ),
      _QuickService(
        'Medical Records',
        Icons.folder_rounded,
        () => context.go('/medical-records'),
      ),
      _QuickService(
        'Upload Record',
        Icons.upload_file_rounded,
        () => context.go('/medical-records'),
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
        childAspectRatio: 2.6,
      ),
      itemBuilder: (context, index) => _QuickServiceTile(item: items[index]),
    );
  }
}

class _HealthSummaryGrid extends StatelessWidget {
  const _HealthSummaryGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      _HealthMetric(
        'Pulse',
        '72 bpm',
        Icons.favorite_rounded,
        Color(0xFFE11D48),
      ),
      _HealthMetric(
        'Blood Pressure',
        '118/76',
        Icons.bloodtype_rounded,
        Color(0xFF2563EB),
      ),
      _HealthMetric(
        'Temperature',
        '36.9 C',
        Icons.thermostat_rounded,
        Color(0xFFF59E0B),
      ),
      _HealthMetric(
        'Weight',
        '68 kg',
        Icons.monitor_weight_rounded,
        Color(0xFF0F766E),
      ),
      _HealthMetric('BMI', '22.4', Icons.show_chart_rounded, Color(0xFF7C3AED)),
    ];

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            _HealthMetricCard(metric: items[index]),
      ),
    );
  }
}

class _NearbyDoctorsSection extends StatelessWidget {
  const _NearbyDoctorsSection({required this.doctors});

  final List<UserModel> doctors;

  @override
  Widget build(BuildContext context) {
    if (doctors.isEmpty) {
      return const _InfoBox(
        message: 'No verified healthcare personnel available yet.',
      );
    }

    final visibleDoctors = doctors.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: visibleDoctors.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) =>
                _DoctorAvatar(doctor: visibleDoctors[index]),
          ),
        ),
        const SizedBox(height: 12),
        ...visibleDoctors.take(3).map(_DoctorCard.new),
      ],
    );
  }
}

class _HealthTipsCarousel extends StatelessWidget {
  const _HealthTipsCarousel();

  @override
  Widget build(BuildContext context) {
    const tips = [
      _Tip(
        'Hydration check',
        'Drink water before your next consultation to help stabilize pulse and pressure readings.',
      ),
      _Tip(
        'Medication routine',
        'Set reminders for recurring medication so missed doses are easier to avoid.',
      ),
      _Tip(
        'Better sleep',
        'Keep a regular sleep time to support recovery and mood.',
      ),
    ];

    return SizedBox(
      height: 132,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.92),
        itemCount: tips.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _TipCard(tip: tips[index]),
        ),
      ),
    );
  }
}

class _MedicationReminderCard extends StatelessWidget {
  const _MedicationReminderCard();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.alarm_rounded,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Take: Paracetamol',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '8:00 PM',
                  style: TextStyle(color: AppTheme.neutralMedium, fontSize: 12),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Mark as Taken'),
          ),
        ],
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

class _QuickServiceTile extends StatelessWidget {
  const _QuickServiceTile({required this.item});

  final _QuickService item;

  @override
  Widget build(BuildContext context) {
    final color = item.isEmergency
        ? AppTheme.errorColor
        : AppTheme.primaryColor;
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
              Icon(item.icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({required this.doctor});

  final UserModel doctor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primarySurface,
                backgroundImage:
                    doctor.profileImage != null &&
                        doctor.profileImage!.isNotEmpty
                    ? NetworkImage(doctor.profileImage!)
                    : null,
                child:
                    doctor.profileImage == null || doctor.profileImage!.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        color: AppTheme.primaryColor,
                      )
                    : null,
              ),
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            doctor.fullName.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard(this.doctor);

  final UserModel doctor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _SurfaceCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primarySurface,
              backgroundImage:
                  doctor.profileImage != null && doctor.profileImage!.isNotEmpty
                  ? NetworkImage(doctor.profileImage!)
                  : null,
              child: doctor.profileImage == null || doctor.profileImage!.isEmpty
                  ? const Icon(
                      Icons.local_hospital_rounded,
                      color: AppTheme.primaryColor,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${doctor.fullName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    doctor.specialty?.isNotEmpty == true
                        ? doctor.specialty!
                        : 'Healthcare Professional',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.neutralMedium,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go('/appointments'),
              child: const Text('Book'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthMetricCard extends StatelessWidget {
  const _HealthMetricCard({required this.metric});

  final _HealthMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, color: metric.color, size: 22),
          const Spacer(),
          Text(
            metric.value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.label,
            style: const TextStyle(color: AppTheme.neutralMedium, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final _Tip tip;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.health_and_safety_rounded,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            tip.title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tip.body,
            style: const TextStyle(
              color: AppTheme.neutralMedium,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile(this.notification);

  final _HomeNotification notification;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _SurfaceCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(notification.icon, color: notification.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: AppTheme.neutralMedium,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.time,
                    style: const TextStyle(
                      color: AppTheme.neutralLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
  const _InfoBox({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _QuickService {
  const _QuickService(
    this.title,
    this.icon,
    this.onTap, {
    this.isEmergency = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isEmergency;
}

class _HealthMetric {
  const _HealthMetric(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _Tip {
  const _Tip(this.title, this.body);

  final String title;
  final String body;
}

class _HomeNotification {
  const _HomeNotification({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
}

String _formatDateTime(DateTime value) {
  final now = DateTime.now();
  final day =
      value.year == now.year && value.month == now.month && value.day == now.day
      ? 'Today'
      : '${value.day}/${value.month}/${value.year}';
  final hour = value.hour == 0 || value.hour == 12 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$day - $hour:$minute $period';
}
