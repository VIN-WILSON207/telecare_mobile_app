import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../appointments/data/models/appointment_model.dart';
import '../../../appointments/providers/appointments_providers.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/theme/app_theme.dart';

class PatientAppointmentsView extends ConsumerStatefulWidget {
  final UserModel user;

  const PatientAppointmentsView({super.key, required this.user});

  @override
  ConsumerState<PatientAppointmentsView> createState() =>
      _PatientAppointmentsViewState();
}

class _PatientAppointmentsViewState
    extends ConsumerState<PatientAppointmentsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _doctorSearchController = TextEditingController();
  String? _selectedSpecialty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _doctorSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(
      patientAppointmentsProvider(widget.user.uid),
    );
    final doctorsAsync = ref.watch(verifiedDoctorsProvider);

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
              Tab(text: 'Book Doctor'),
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'History'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Book Doctor
          RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async => ref.invalidate(verifiedDoctorsProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Healthcare Providers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutralDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select a verified physician to request an online consultation',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutralLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  doctorsAsync.when(
                    data: (doctors) {
                      if (doctors.isEmpty) {
                        return const _EmptyState(
                          icon: Icons.person_search_rounded,
                          message: 'No verified doctors available yet.',
                        );
                      }
                      final filteredDoctors = _filterDoctors(doctors);
                      final specialties =
                          doctors
                              .map((doctor) => doctor.specialty?.trim() ?? '')
                              .where((specialty) => specialty.isNotEmpty)
                              .toSet()
                              .toList()
                            ..sort();
                      return Column(
                        children: [
                          TextField(
                            controller: _doctorSearchController,
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.search,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 17,
                            ),
                            decoration: const InputDecoration(
                              hintText:
                                  'Search by doctor, specialty, or hospital',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                          ),
                          if (specialties.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 42,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: specialties.length + 1,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final isAll = index == 0;
                                  final value = isAll
                                      ? null
                                      : specialties[index - 1];
                                  final selected =
                                      isAll && _selectedSpecialty == null ||
                                      value == _selectedSpecialty;
                                  return ChoiceChip(
                                    label: Text(isAll ? 'All' : value!),
                                    selected: selected,
                                    onSelected: (_) => setState(
                                      () => _selectedSpecialty = value,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (filteredDoctors.isEmpty)
                            const _EmptyState(
                              icon: Icons.manage_search_rounded,
                              message:
                                  'No doctors match this search or filter.',
                            )
                          else
                            ...filteredDoctors.map(
                              (doctor) => _PatientDoctorCard(
                                doctor: doctor,
                                patient: widget.user,
                                ref: ref,
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, _) => _ErrorCard(message: error.toString()),
                  ),
                ],
              ),
            ),
          ),

          // Tab 2: Pending appointments
          RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async =>
                ref.invalidate(patientAppointmentsProvider(widget.user.uid)),
            child: appointmentsAsync.when(
              data: (list) {
                final pendingList = list
                    .where((a) => a.status.toLowerCase() == 'pending')
                    .toList();

                if (pendingList.isEmpty) {
                  return const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 80,
                        horizontal: 24,
                      ),
                      child: _EmptyState(
                        icon: Icons.hourglass_top_rounded,
                        message:
                            'No pending appointment requests.\nTap "Book Doctor" to request a slot.',
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: pendingList.length,
                  itemBuilder: (context, idx) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PatientAppointmentCard(
                      appointment: pendingList[idx],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(20.0),
                child: _ErrorCard(message: err.toString()),
              ),
            ),
          ),

          // Tab 3: Approved appointments
          RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async =>
                ref.invalidate(patientAppointmentsProvider(widget.user.uid)),
            child: appointmentsAsync.when(
              data: (list) {
                final approvedList = list
                    .where((a) => a.status.toLowerCase() == 'approved')
                    .toList();

                if (approvedList.isEmpty) {
                  return const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 80,
                        horizontal: 24,
                      ),
                      child: _EmptyState(
                        icon: Icons.event_available_rounded,
                        message: 'No approved appointments yet.',
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: approvedList.length,
                  itemBuilder: (context, idx) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PatientAppointmentCard(
                      appointment: approvedList[idx],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(20.0),
                child: _ErrorCard(message: err.toString()),
              ),
            ),
          ),

          // Tab 4: Consultation history (Completed & Rejected)
          RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async =>
                ref.invalidate(patientAppointmentsProvider(widget.user.uid)),
            child: appointmentsAsync.when(
              data: (list) {
                final historyList = list
                    .where(
                      (a) =>
                          a.status.toLowerCase() == 'completed' ||
                          a.status.toLowerCase() == 'rejected',
                    )
                    .toList();

                if (historyList.isEmpty) {
                  return const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 80,
                        horizontal: 24,
                      ),
                      child: _EmptyState(
                        icon: Icons.history_rounded,
                        message: 'No past appointment history found.',
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: historyList.length,
                  itemBuilder: (context, idx) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PatientAppointmentCard(
                      appointment: historyList[idx],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(20.0),
                child: _ErrorCard(message: err.toString()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<UserModel> _filterDoctors(List<UserModel> doctors) {
    final query = _doctorSearchController.text.trim().toLowerCase();
    return doctors.where((doctor) {
      final specialty = doctor.specialty?.trim() ?? '';
      final matchesSpecialty =
          _selectedSpecialty == null || specialty == _selectedSpecialty;
      final searchable = [
        doctor.fullName,
        doctor.email,
        specialty,
        doctor.hospital ?? '',
      ].join(' ').toLowerCase();
      return matchesSpecialty && (query.isEmpty || searchable.contains(query));
    }).toList();
  }
}

// ── Patient Doctor Card ─────────────────────────────────────────────────────────────
class _PatientDoctorCard extends StatelessWidget {
  final UserModel doctor;
  final UserModel patient;
  final WidgetRef ref;

  const _PatientDoctorCard({
    required this.doctor,
    required this.patient,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.primarySurface,
            backgroundImage:
                doctor.profileImage != null && doctor.profileImage!.isNotEmpty
                ? NetworkImage(doctor.profileImage!)
                : null,
            child: doctor.profileImage == null || doctor.profileImage!.isEmpty
                ? const Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: 26,
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutralDark,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: const [
                    Icon(
                      Icons.verified_rounded,
                      color: AppTheme.primaryColor,
                      size: 13,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Verified Doctor',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  doctor.email,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _showBookingDialog(context, ref, patient, doctor),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Book',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBookingDialog(
    BuildContext context,
    WidgetRef ref,
    UserModel patient,
    UserModel doctor,
  ) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book with Dr. ${doctor.fullName}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Describe your reason for the visit',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neutralMedium,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. Headache, general check-up...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(ctx).pop(reasonController.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (reason == null || !context.mounted) return;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(hours: 1)),
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (time == null || !context.mounted) return;

    final appointmentDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final repository = ref.read(appointmentRepositoryProvider);
    await repository.createAppointment(
      patientId: patient.uid,
      doctorId: doctor.uid,
      patientName: patient.fullName,
      doctorName: doctor.fullName,
      patientEmail: patient.email,
      doctorEmail: doctor.email,
      reason: reason.isEmpty
          ? 'Requested consultation with Dr. ${doctor.fullName}'
          : reason,
      appointmentDate: appointmentDate,
      notes: 'Requested from TeleCare mobile app.',
    );

    // Task 19 — notify doctor of the new appointment request (non-blocking)
    try {
      final notificationSvc = ref.read(notificationServiceProvider);
      final payload = NotificationService.buildAppointmentRequestPayload(
        patientName: patient.fullName.isNotEmpty ? patient.fullName : 'A patient',
        appointmentDate: _formatAppointmentDate(appointmentDate),
      );
      notificationSvc.sendNotification(
        targetUserId: doctor.uid,
        title: payload['title'] as String,
        body: payload['body'] as String,
        data: Map<String, String>.from(payload['data'] as Map),
      ).catchError((_) {}); // fire-and-forget
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment request sent to Dr. ${doctor.fullName}'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static String _formatAppointmentDate(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Patient Appointment Card ──────────────────────────────────────────────────
class _PatientAppointmentCard extends StatelessWidget {

  final AppointmentModel appointment;

  const _PatientAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(appointment.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusInfo.$3,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medical_services_outlined,
                  color: statusInfo.$2,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${appointment.doctorName}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutralDark,
                      ),
                    ),
                    Text(
                      appointment.reason,
                      style: Theme.of(context).textTheme.bodySmall,
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
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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
                size: 14,
                color: AppTheme.neutralLight,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(appointment.appointmentDate),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
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
