import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../appointments/providers/appointments_providers.dart';
import '../../../../core/theme/app_theme.dart';

class DoctorPatientsView extends ConsumerWidget {
  final UserModel user;

  const DoctorPatientsView({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider(user.uid));

    // Deduplicate patients from appointments list
    final patients = appointmentsAsync.maybeWhen(
      data: (list) {
        final uniquePatientIds = <String>{};
        final uniquePatients = <_PatientListItem>[];
        for (final app in list) {
          if (!uniquePatientIds.contains(app.patientId)) {
            uniquePatientIds.add(app.patientId);
            uniquePatients.add(_PatientListItem(
              uid: app.patientId,
              fullName: app.patientName,
              email: app.patientEmail,
              lastConsultationDate: app.appointmentDate,
            ));
          }
        }
        return uniquePatients;
      },
      orElse: () => <_PatientListItem>[],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async {
          ref.invalidate(doctorAppointmentsProvider(user.uid));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search input
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search patients or files...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.neutralLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Patient list section
              const Text(
                'Consulted Patients',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.neutralDark),
              ),
              const SizedBox(height: 12),
              if (patients.isEmpty)
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
                      Icon(Icons.people_outline_rounded, size: 40, color: AppTheme.neutralLight),
                      SizedBox(height: 8),
                      Text(
                        'No previous patient records found.',
                        style: TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: patients.map((patient) {
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
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppTheme.primarySurface,
                            child: Text(
                              patient.fullName.isNotEmpty ? patient.fullName[0].toUpperCase() : 'P',
                              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.neutralDark),
                                ),
                                Text(
                                  patient.email,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.neutralLight),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Last Consulted: ${_formatDate(patient.lastConsultationDate)}',
                                  style: const TextStyle(fontSize: 10, color: AppTheme.neutralMedium, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.folder_shared_rounded, color: AppTheme.primaryColor),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Requesting medical records access for ${patient.fullName}...')),
                              );
                            },
                            tooltip: 'Request File Access',
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _PatientListItem {
  final String uid;
  final String fullName;
  final String email;
  final DateTime lastConsultationDate;

  _PatientListItem({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.lastConsultationDate,
  });
}
