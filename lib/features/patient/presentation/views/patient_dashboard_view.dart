import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/widgets/telecare_ui.dart';
import '../../../appointments/data/models/appointment_model.dart';
import '../../../appointments/providers/appointments_providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/models/user_role.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../medical_records/providers/medical_record_providers.dart';
import '../../../consultation/providers/consultation_providers.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
              onEmergency: () => _showEmergencyDialog(context, ref, user),
            ),
            const SizedBox(height: 26),
            _SectionHeader(
              title: 'Health Summary',
              actionLabel: 'Edit',
              onAction: () => _showEditSummaryDialog(context, ref, user),
            ),
            const SizedBox(height: 12),
            _HealthSummaryGrid(user: user),
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
            _MedicationReminderCard(user: user),
            const SizedBox(height: 26),
            _SectionHeader(title: 'Notifications'),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: ref.watch(notificationServiceProvider).watchUserNotifications(user.uid),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const _InfoBox(message: 'No notifications at this time.');
                }
                return Column(
                  children: docs.take(5).map((doc) {
                    final data = doc.data();
                    final title = data['title'] as String? ?? '';
                    final body = data['body'] as String? ?? '';
                    final type = data['type'] as String? ?? 'general';
                    final timestampVal = data['createdAt'];
                    
                    DateTime? dt;
                    if (timestampVal is Timestamp) {
                      dt = timestampVal.toDate();
                    } else if (timestampVal is String) {
                      dt = DateTime.tryParse(timestampVal);
                    }
                    final timeStr = dt != null ? DateFormat('jm').format(dt) : 'Now';

                    IconData icon;
                    Color color;
                    switch (type) {
                      case 'appointment_approved':
                      case 'appointment_confirmed':
                        icon = Icons.event_available_rounded;
                        color = AppTheme.primaryColor;
                        break;
                      case 'consultation_started':
                        icon = Icons.video_call_rounded;
                        color = AppTheme.accentColor;
                        break;
                      case 'prescription':
                      case 'prescription_added':
                        icon = Icons.medication_rounded;
                        color = AppTheme.accentAlt;
                        break;
                      default:
                        icon = Icons.notifications_active_rounded;
                        color = AppTheme.infoColor;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NotificationTile(
                        _HomeNotification(
                          title: title,
                          message: body,
                          time: timeStr,
                          icon: icon,
                          color: color,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
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

  void _showEmergencyDialog(BuildContext context, WidgetRef ref, UserModel patient) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency SOS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe your medical emergency. This message will be broadcasted to all available healthcare professionals immediately.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              maxLines: 3,
              style: TeleCareInputStyles.formTextStyle,
              decoration: const InputDecoration(
                hintText: 'e.g. Sharp chest pain, difficulty breathing...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final desc = controller.text.trim();
              if (desc.isEmpty) return;
              Navigator.pop(ctx);
              
              // Broadcast to online HPs
              try {
                final firestore = ref.read(firestoreProvider);
                final chatRepo = ref.read(chatRepositoryProvider);
                final notifSvc = ref.read(notificationServiceProvider);
                
                final snapshot = await firestore
                    .collection('users')
                    .where('role', whereIn: ['doctor', 'nurse', 'pharmacist', 'physiotherapist', 'lab_technician'])
                    .where('isOnline', isEqualTo: true)
                    .get();
                
                final hps = snapshot.docs;
                if (hps.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No available healthcare personnel online right now. Dialing emergency services...'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }
                
                int count = 0;
                for (final hpDoc in hps) {
                  final hpId = hpDoc.id;
                  
                  final roomId = chatRepo.roomIdForPair(doctorId: hpId, patientId: patient.uid);
                  await chatRepo.getOrCreateRoom(
                    doctorId: hpId,
                    patientId: patient.uid,
                    appointmentId: '',
                    consultationId: '',
                  );
                  
                  await chatRepo.sendRoomMessage(
                    roomId: roomId,
                    senderId: patient.uid,
                    senderName: patient.fullName,
                    text: '⚠️ EMERGENCY SOS: $desc',
                  );
                  
                  await notifSvc.sendNotification(
                    targetUserId: hpId,
                    title: '🚨 EMERGENCY SOS 🚨',
                    body: '${patient.fullName} needs help: $desc',
                    data: {
                      'type': 'emergency_sos',
                      'patientId': patient.uid,
                      'roomId': roomId,
                    },
                  );
                  count++;
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Emergency broadcasted successfully to $count online HP(s).'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to broadcast: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Broadcast SOS'),
          ),
        ],
      ),
    );
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
  const _HealthSummaryGrid({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    // Calculate BMI dynamically
    String bmiStr = 'N/A';
    if (user.weight != null && user.height != null && user.height! > 0) {
      final heightInMeters = user.height! / 100.0;
      final bmi = user.weight! / (heightInMeters * heightInMeters);
      bmiStr = bmi.toStringAsFixed(1);
    }

    final items = [
      _HealthMetric(
        'Pulse',
        user.pulse != null ? '${user.pulse} bpm' : 'N/A',
        Icons.favorite_rounded,
        const Color(0xFFE11D48),
      ),
      _HealthMetric(
        'Blood Pressure',
        user.bloodPressure ?? 'N/A',
        Icons.bloodtype_rounded,
        const Color(0xFF2563EB),
      ),
      _HealthMetric(
        'Temperature',
        user.temperature != null ? '${user.temperature} °C' : 'N/A',
        Icons.thermostat_rounded,
        const Color(0xFFF59E0B),
      ),
      _HealthMetric(
        'Weight',
        user.weight != null ? '${user.weight} kg' : 'N/A',
        Icons.monitor_weight_rounded,
        const Color(0xFF0F766E),
      ),
      _HealthMetric(
        'Height',
        user.height != null ? '${user.height} cm' : 'N/A',
        Icons.height,
        const Color(0xFF8B5CF6),
      ),
      _HealthMetric('BMI', bmiStr, Icons.show_chart_rounded, const Color(0xFF7C3AED)),
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

    final visibleDoctors = doctors.where((doc) => doc.role != UserRole.patient).take(6).toList();
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

class _HealthTipsCarousel extends ConsumerWidget {
  const _HealthTipsCarousel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = ref.watch(firestoreProvider);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore
          .collection('safety_measures')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          final defaultTips = [
            const _Tip(
              'Hydration check',
              'Drink water before your next consultation to help stabilize pulse and pressure readings.',
            ),
            const _Tip(
              'Medication routine',
              'Set reminders for recurring medication so missed doses are easier to avoid.',
            ),
            const _Tip(
              'Better sleep',
              'Keep a regular sleep time to support recovery and mood.',
            ),
          ];
          return _buildTipsPageView(defaultTips);
        }

        final tips = docs.map((doc) {
          final data = doc.data();
          final title = data['title'] as String? ?? 'Health Tip';
          final content = data['content'] as String? ?? '';
          final category = data['category'] as String? ?? 'General';
          final hpName = data['hpName'] as String? ?? 'HP';
          return _Tip('$title (by $hpName)', '$content [$category]');
        }).toList();

        return _buildTipsPageView(tips);
      },
    );
  }

  Widget _buildTipsPageView(List<_Tip> tips) {
    return SizedBox(
      height: 142,
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

class _MedicationReminderCard extends ConsumerWidget {
  const _MedicationReminderCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(patientMedicalRecordsProvider(user.uid));

    return recordsAsync.when(
      loading: () => const _LoadingLine(),
      error: (e, _) => _InfoBox(message: 'Unable to load prescriptions: $e'),
      data: (records) {
        final recordWithPrescription = records
            .where((r) => r.prescription.isNotEmpty)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        String medicineName = 'No active medications';
        String dosageStr = 'Check back later';

        if (recordWithPrescription.isNotEmpty) {
          final latestPresc = recordWithPrescription.first.prescription.first;
          medicineName = 'Take: ${latestPresc.medicine}';
          dosageStr = '${latestPresc.dosage} - ${latestPresc.duration}';
        }

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicineName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dosageStr,
                      style: const TextStyle(color: AppTheme.neutralMedium, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (recordWithPrescription.isNotEmpty)
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prescription marked as taken.')),
                    );
                  },
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
      },
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              tip.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.neutralMedium,
                fontSize: 12,
                height: 1.35,
              ),
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

Future<void> _showEditSummaryDialog(BuildContext context, WidgetRef ref, UserModel user) async {
  final formKey = GlobalKey<FormState>();
  final pulseController = TextEditingController(text: user.pulse?.toString() ?? '');
  final bpController = TextEditingController(text: user.bloodPressure ?? '');
  final tempController = TextEditingController(text: user.temperature?.toString() ?? '');
  final weightController = TextEditingController(text: user.weight?.toString() ?? '');
  final heightController = TextEditingController(text: user.height?.toString() ?? '');
  final bgController = TextEditingController(text: user.bloodGroup ?? '');

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit Health Summary'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: pulseController,
                keyboardType: TextInputType.number,
                style: TeleCareInputStyles.formTextStyle,
                decoration: const InputDecoration(labelText: 'Pulse (bpm)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bpController,
                style: TeleCareInputStyles.formTextStyle,
                decoration: const InputDecoration(labelText: 'Blood Pressure (e.g. 120/80)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: tempController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TeleCareInputStyles.formTextStyle,
                decoration: const InputDecoration(labelText: 'Temperature (°C)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TeleCareInputStyles.formTextStyle,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TeleCareInputStyles.formTextStyle,
                decoration: const InputDecoration(labelText: 'Height (cm)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].contains(bgController.text) ? bgController.text : null,
                style: TeleCareInputStyles.formTextStyle,
                decoration: const InputDecoration(labelText: 'Blood Group'),
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                    .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) bgController.text = val;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              Navigator.pop(ctx);
              try {
                await ref.read(authRepositoryProvider).updatePatientVitals(
                  uid: user.uid,
                  bloodPressure: bpController.text.trim(),
                  weight: weightController.text.trim(),
                  height: heightController.text.trim(),
                  bloodGroup: bgController.text.trim(),
                  pulse: pulseController.text.trim(),
                  temperature: tempController.text.trim(),
                );

                // Refresh notifier state
                final updatedProfile = await ref.read(authRepositoryProvider).getUserProfile(user.uid);
                if (updatedProfile != null) {
                  ref.read(authNotifierProvider.notifier).updateAuthenticatedUser(updatedProfile);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Health summary updated successfully!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
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
