import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/models/user_model.dart';
import '../../auth/data/models/user_role.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/auth_state.dart';
import '../data/models/appointment_model.dart';
import '../providers/appointments_providers.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Sign in to manage appointments.')),
      );
    }

    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(user.role == UserRole.doctor
            ? 'Appointment Requests'
            : 'Appointments'),
      ),
      body: user.role == UserRole.patient
          ? _PatientAppointmentsView(user: user)
          : user.role == UserRole.doctor
              ? _DoctorAppointmentsView(user: user)
              : const Center(child: Text('Appointment management is available for patients and doctors.')),
    );
  }
}

class _PatientAppointmentsView extends ConsumerWidget {
  const _PatientAppointmentsView({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(verifiedDoctorsProvider);
    final appointmentsAsync = ref.watch(patientAppointmentsProvider(user.uid));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(verifiedDoctorsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Verified doctors', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Book a consultation with an approved physician.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          doctorsAsync.when(
            data: (List<UserModel> doctors) {
              if (doctors.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No verified doctors are available yet.'),
                  ),
                );
              }

              return Column(
                children: doctors.map((doctor) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: doctor.profileImage != null && doctor.profileImage!.isNotEmpty
                                  ? NetworkImage(doctor.profileImage!)
                                  : null,
                              child: doctor.profileImage == null || doctor.profileImage!.isEmpty
                                  ? const Icon(Icons.medical_services)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(doctor.fullName, style: Theme.of(context).textTheme.titleMedium),
                                  Text('Verified doctor', style: Theme.of(context).textTheme.bodySmall),
                                  Text(doctor.email, style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => _bookAppointment(context, ref, user, doctor),
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: const Text('Book appointment'),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('Unable to load doctors: $error'),
          ),
          const SizedBox(height: 24),
          Text('My appointments', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          appointmentsAsync.when(
            data: (List<AppointmentModel> appointments) {
              if (appointments.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No appointment requests yet.'),
                  ),
                );
              }

              return Column(
                children: appointments.map((appointment) => _AppointmentCard(appointment: appointment)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('Unable to load appointments: $error'),
          ),
        ],
      ),
    );
  }

  Future<void> _bookAppointment(
    BuildContext context,
    WidgetRef ref,
    UserModel patient,
    UserModel doctor,
  ) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Book appointment with ${doctor.fullName}'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason for visit',
              hintText: 'Describe the concern or consultation reason',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(reasonController.text.trim()),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (reason == null) return;

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (time == null) return;

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
          ? 'Requested consultation with ${doctor.fullName}'
          : reason,
      appointmentDate: appointmentDate,
      notes: 'Requested from TeleCare mobile app.',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment request sent to ${doctor.fullName}')),
      );
    }
  }
}

class _DoctorAppointmentsView extends ConsumerWidget {
  const _DoctorAppointmentsView({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider(user.uid));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(doctorAppointmentsProvider(user.uid));
      },
      child: appointmentsAsync.when(
        data: (List<AppointmentModel> appointments) {
          if (appointments.isEmpty) {
            return const Center(child: Text('You have no appointment requests yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return _AppointmentCard(
                appointment: appointment,
                showDoctorActions: true,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Unable to load appointment requests: $error')),
      ),
    );
  }
}

class _AppointmentCard extends ConsumerWidget {
  const _AppointmentCard({required this.appointment, this.showDoctorActions = false});

  final AppointmentModel appointment;
  final bool showDoctorActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(appointmentRepositoryProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    showDoctorActions ? 'Request from ${appointment.patientName}' : 'Booking with ${appointment.doctorName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(appointment.status.toUpperCase()),
                  backgroundColor: _statusColor(appointment.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Reason: ${appointment.reason}'),
            const SizedBox(height: 4),
            Text('When: ${_formatDate(appointment.appointmentDate)}'),
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Notes: ${appointment.notes}'),
            ],
            if (showDoctorActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        await repository.updateAppointmentStatus(appointment.id, status: 'approved');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Appointment approved.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await repository.updateAppointmentStatus(appointment.id, status: 'rejected');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Appointment rejected.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFFB9F6CA);
      case 'rejected':
        return const Color(0xFFFFCCBC);
      case 'completed':
        return const Color(0xFFE3F2FD);
      case 'pending':
      default:
        return const Color(0xFFFFF3CD);
    }
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
