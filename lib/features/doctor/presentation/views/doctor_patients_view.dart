import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../appointments/providers/appointments_providers.dart';
import '../../../medical_records/providers/medical_record_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/telecare_ui.dart';

class DoctorPatientsView extends ConsumerStatefulWidget {
  final UserModel user;

  const DoctorPatientsView({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<DoctorPatientsView> createState() => _DoctorPatientsViewState();
}

class _DoctorPatientsViewState extends ConsumerState<DoctorPatientsView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPatientRecordsSheet(BuildContext context, _PatientListItem patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.neutralBackground,
      builder: (context) {
        return _PatientRecordsSheet(patient: patient);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider(widget.user.uid));

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

    final filteredPatients = patients.where((patient) {
      if (_searchQuery.isEmpty) return true;
      return patient.fullName.toLowerCase().contains(_searchQuery) ||
          patient.email.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async {
          ref.invalidate(doctorAppointmentsProvider(widget.user.uid));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search input
              TextField(
                controller: _searchController,
                style: TeleCareInputStyles.formTextStyle,
                decoration: InputDecoration(
                  hintText: 'Search patients or files...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.neutralLight),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close_rounded, color: AppTheme.neutralLight),
                        ),
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
              if (filteredPatients.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 40, color: AppTheme.neutralLight),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No previous patient records found.'
                            : 'No patients match your search.',
                        style: const TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: filteredPatients.map((patient) {
                    return InkWell(
                      onTap: () => _showPatientRecordsSheet(context, patient),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
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
                              onPressed: () => _showPatientRecordsSheet(context, patient),
                              tooltip: 'View Medical Records',
                            ),
                          ],
                        ),
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

class _PatientRecordsSheet extends ConsumerWidget {
  final _PatientListItem patient;

  const _PatientRecordsSheet({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(patientMedicalRecordsProvider(patient.uid));

    return Scaffold(
      appBar: AppBar(
        title: Text('${patient.fullName} - Records History'),
        backgroundColor: AppTheme.neutralBackground,
        elevation: 0,
        foregroundColor: AppTheme.neutralDark,
      ),
      backgroundColor: AppTheme.neutralBackground,
      body: recordsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No medical records have been uploaded for this patient yet.',
                  style: TextStyle(color: AppTheme.neutralMedium),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            record.diagnosis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neutralDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatDate(record.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.neutralLight,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    const Text(
                      'Symptoms',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.neutralMedium),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.symptoms.join(', '),
                      style: const TextStyle(fontSize: 13, color: AppTheme.neutralDark),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Treatment Plan',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.neutralMedium),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.treatmentPlan,
                      style: const TextStyle(fontSize: 13, color: AppTheme.neutralDark),
                    ),
                    if (record.prescription.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Prescription',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.neutralMedium),
                      ),
                      const SizedBox(height: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: record.prescription.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '• ${p.medicine} (${p.dosage} for ${p.duration})',
                            style: const TextStyle(fontSize: 13, color: AppTheme.neutralDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                      ),
                    ],
                    if (record.notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Clinical Notes',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.neutralMedium),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.notes,
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppTheme.neutralDark),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (e, _) => Center(
          child: Text('Error loading medical records: $e'),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
