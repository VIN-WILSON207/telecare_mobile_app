import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../appointments/data/models/appointment_model.dart';
import '../../../appointments/providers/appointments_providers.dart';
import '../../../consultation/data/exceptions/consultation_exceptions.dart';
import '../../../consultation/providers/consultation_providers.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class DoctorAppointmentsView extends ConsumerStatefulWidget {
  final UserModel user;

  const DoctorAppointmentsView({super.key, required this.user});

  @override
  ConsumerState<DoctorAppointmentsView> createState() =>
      _DoctorAppointmentsViewState();
}

class _DoctorAppointmentsViewState extends ConsumerState<DoctorAppointmentsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(
      doctorAppointmentsProvider(widget.user.uid),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppTheme.cardWhite,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.neutralLight,
            indicatorColor: AppTheme.primaryColor,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Requests'),
              Tab(text: 'Approved'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Requests (Pending)
          RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async =>
                ref.invalidate(doctorAppointmentsProvider(widget.user.uid)),
            child: appointmentsAsync.when(
              data: (list) {
                final pendingList = list
                    .where((a) => a.status.toLowerCase() == 'pending')
                    .toList();
                if (pendingList.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 80,
                        horizontal: 24,
                      ),
                      child: _EmptyState(
                        icon: Icons.inbox_rounded,
                        message: 'No pending appointment requests.',
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: pendingList.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DoctorRequestCard(
                      appointment: pendingList[index],
                      ref: ref,
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorCard(message: err.toString()),
            ),
          ),

          // Tab 2: Approved Bookings
          RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async =>
                ref.invalidate(doctorAppointmentsProvider(widget.user.uid)),
            child: appointmentsAsync.when(
              data: (list) {
                final approvedList = list
                    .where((a) => a.status.toLowerCase() == 'approved')
                    .toList();
                if (approvedList.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 80,
                        horizontal: 24,
                      ),
                      child: const _EmptyState(
                        icon: Icons.event_available_rounded,
                        message: 'No approved bookings scheduled.',
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: approvedList.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DoctorAppointmentCard(
                      appointment: approvedList[index],
                      ref: ref,
                      canComplete: true,
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorCard(message: err.toString()),
            ),
          ),

          // Tab 3: Completed Appointments
          RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async =>
                ref.invalidate(doctorAppointmentsProvider(widget.user.uid)),
            child: appointmentsAsync.when(
              data: (list) {
                final completedList = list
                    .where(
                      (a) =>
                          a.status.toLowerCase() == 'completed' ||
                          a.status.toLowerCase() == 'rejected',
                    )
                    .toList();
                if (completedList.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 80,
                        horizontal: 24,
                      ),
                      child: const _EmptyState(
                        icon: Icons.history_rounded,
                        message: 'No completed appointments in log history.',
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: completedList.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DoctorAppointmentCard(
                      appointment: completedList[index],
                      ref: ref,
                      canComplete: false,
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorCard(message: err.toString()),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Doctor Request Card ──────────────────────────────────────────────────────
class _DoctorRequestCard extends StatelessWidget {
  final AppointmentModel appointment;
  final WidgetRef ref;

  const _DoctorRequestCard({required this.appointment, required this.ref});

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(appointmentRepositoryProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primarySurface,
                child: Text(
                  appointment.patientName.isNotEmpty
                      ? appointment.patientName[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.neutralDark,
                      ),
                    ),
                    Text(
                      appointment.reason,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutralMedium,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.statusPending,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(
                    color: AppTheme.statusPendingText,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: AppTheme.neutralLight,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(appointment.appointmentDate),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.neutralMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final consultationRepo =
                        ref.read(consultationRepositoryProvider);
                    final notificationSvc =
                        ref.read(notificationServiceProvider);
                    final appointmentRepo =
                        ref.read(appointmentRepositoryProvider);

                    try {
                      // Step 1: Create consultation (throws on duplicate or Firestore fail)
                      await consultationRepo.createConsultation(appointment);
                    } on DuplicateConsultationException {
                      // Consultation already exists — still approve
                    } on ConsultationCreationException {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to create consultation session. Please try again.',
                            ),
                          ),
                        );
                      }
                      return; // Do NOT update appointment status
                    }

                    // Step 2: Notify patient
                    try {
                      final payload =
                          NotificationService.buildAppointmentApprovedPayload(
                        doctorName: appointment.doctorName,
                        appointmentDate:
                            _formatDate(appointment.appointmentDate),
                      );
                      await notificationSvc.sendNotification(
                        targetUserId: appointment.patientId,
                        title: payload['title'] as String,
                        body: payload['body'] as String,
                        data: Map<String, String>.from(
                            payload['data'] as Map),
                      );
                    } catch (_) {
                      // Notification failure is non-blocking
                    }

                    // Step 3: Update appointment status
                    await appointmentRepo.updateAppointmentStatus(
                      appointment.id,
                      status: 'approved',
                    );
                    ref.invalidate(
                      doctorAppointmentsProvider(appointment.doctorId),
                    );
                  },
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: const Text(
                    'Approve',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await repository.updateAppointmentStatus(
                      appointment.id,
                      status: 'rejected',
                    );
                    ref.invalidate(
                      doctorAppointmentsProvider(appointment.doctorId),
                    );
                  },
                  icon: const Icon(Icons.close_rounded, size: 14),
                  label: const Text(
                    'Decline',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(
                      color: AppTheme.errorColor,
                      width: 1.5,
                    ),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} at $h:$m';
  }
}

// ── Doctor Appointment Card ──────────────────────────────────────────────────
class _DoctorAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final WidgetRef ref;
  final bool canComplete;

  const _DoctorAppointmentCard({
    required this.appointment,
    required this.ref,
    required this.canComplete,
  });

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(appointmentRepositoryProvider);
    final statusInfo = _statusInfo(appointment.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusInfo.$3,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person, color: statusInfo.$2, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.neutralDark,
                      ),
                    ),
                    Text(
                      appointment.reason,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutralMedium,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusInfo.$3,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  appointment.status.toUpperCase(),
                  style: TextStyle(
                    color: statusInfo.$2,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: AppTheme.neutralLight,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(appointment.appointmentDate),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.neutralMedium,
                ),
              ),
            ],
          ),
          if (appointment.status.toLowerCase() == 'approved') ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.phone_enabled_rounded, size: 14),
              label: const Text(
                'Launch Consultation Call',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => launchCall(context, ref, appointment),
            ),
          ],
          if (canComplete) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await repository.updateAppointmentStatus(
                  appointment.id,
                  status: 'completed',
                );
                ref.invalidate(
                  doctorAppointmentsProvider(appointment.doctorId),
                );
              },
              icon: const Icon(Icons.check_circle_rounded, size: 14),
              label: const Text(
                'Mark as Completed',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static (String, Color, Color) _statusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return (
          'Approved',
          AppTheme.statusApprovedText,
          AppTheme.statusApproved,
        );
      case 'rejected':
        return (
          'Rejected',
          AppTheme.statusRejectedText,
          AppTheme.statusRejected,
        );
      case 'completed':
        return (
          'Completed',
          AppTheme.statusCompletedText,
          AppTheme.statusCompleted,
        );
      default:
        return ('Pending', AppTheme.statusPendingText, AppTheme.statusPending);
    }
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} at $h:$m';
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppTheme.neutralLight),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.statusRejected,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.statusRejectedText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.statusRejectedText),
            ),
          ),
        ],
      ),
    );
  }
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
