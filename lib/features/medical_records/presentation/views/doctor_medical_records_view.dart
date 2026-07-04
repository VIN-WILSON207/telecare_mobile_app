import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../appointments/data/models/appointment_model.dart';
import '../../../appointments/providers/appointments_providers.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/medical_record_model.dart';
import '../../providers/medical_record_providers.dart';
import '../../../verification/services/cloudinary_service.dart';
import '../../../../core/theme/app_theme.dart';

class DoctorMedicalRecordsView extends ConsumerStatefulWidget {
  final UserModel user;

  const DoctorMedicalRecordsView({super.key, required this.user});

  @override
  ConsumerState<DoctorMedicalRecordsView> createState() =>
      _DoctorMedicalRecordsViewState();
}

class _DoctorMedicalRecordsViewState
    extends ConsumerState<DoctorMedicalRecordsView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(
      doctorMedicalRecordsProvider(widget.user.uid),
    );
    final appointmentsAsync = ref.watch(
      doctorAppointmentsProvider(widget.user.uid),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _openCreateSheet(context, appointmentsAsync),
        icon: const Icon(Icons.note_add_rounded),
        label: const Text('New Record'),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async {
          ref.invalidate(doctorMedicalRecordsProvider(widget.user.uid));
          ref.invalidate(doctorAppointmentsProvider(widget.user.uid));
        },
        child: recordsAsync.when(
          data: (records) {
            final filtered = _filter(records);
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 92),
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search patient, diagnosis, medicine...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                _DoctorSummary(records: records),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const _EmptyState(
                    icon: Icons.folder_shared_rounded,
                    message: 'No medical records have been created yet.',
                  )
                else
                  ...filtered.map(
                    (record) => _DoctorRecordCard(record: record),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _EmptyState(
            icon: Icons.error_outline_rounded,
            message: error.toString(),
          ),
        ),
      ),
    );
  }

  List<MedicalRecordModel> _filter(List<MedicalRecordModel> records) {
    if (_query.isEmpty) return records;
    return records.where((record) {
      final text = [
        record.patientName,
        record.diagnosis,
        record.symptoms.join(' '),
        record.treatmentPlan,
        record.prescription.map((item) => item.medicine).join(' '),
      ].join(' ').toLowerCase();
      return text.contains(_query);
    }).toList();
  }

  void _openCreateSheet(
    BuildContext context,
    AsyncValue<List<AppointmentModel>> appointmentsAsync,
  ) {
    appointmentsAsync.when(
      data: (appointments) {
        final eligible = appointments
            .where(
              (appointment) =>
                  appointment.status.toLowerCase() == 'completed' ||
                  appointment.status.toLowerCase() == 'approved',
            )
            .toList();
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: AppTheme.neutralBackground,
          builder: (_) =>
              _CreateRecordSheet(doctor: widget.user, appointments: eligible),
        );
      },
      loading: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Loading appointments...'))),
      error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load appointments: $error')),
      ),
    );
  }
}

class _CreateRecordSheet extends ConsumerStatefulWidget {
  final UserModel doctor;
  final List<AppointmentModel> appointments;

  const _CreateRecordSheet({required this.doctor, required this.appointments});

  @override
  ConsumerState<_CreateRecordSheet> createState() => _CreateRecordSheetState();
}

class _CreateRecordSheetState extends ConsumerState<_CreateRecordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _medicineController = TextEditingController();
  final _dosageController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  final _attachments = <String>[];
  AppointmentModel? _selectedAppointment;
  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.appointments.isNotEmpty) {
      _selectedAppointment = widget.appointments.first;
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _symptomsController.dispose();
    _treatmentController.dispose();
    _medicineController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Create Medical Record',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutralDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.appointments.isEmpty)
                const _EmptyState(
                  icon: Icons.event_busy_rounded,
                  message:
                      'No approved or completed appointments are ready for records.',
                )
              else ...[
                DropdownButtonFormField<AppointmentModel>(
                  initialValue: _selectedAppointment,
                  decoration: const InputDecoration(
                    labelText: 'Patient appointment',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  items: widget.appointments
                      .map(
                        (appointment) => DropdownMenuItem(
                          value: appointment,
                          child: Text(
                            '${appointment.patientName} - ${DateFormat('dd MMM').format(appointment.appointmentDate)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedAppointment = value),
                  validator: (value) =>
                      value == null ? 'Select an appointment.' : null,
                ),
                const SizedBox(height: 12),
                _RequiredTextField(
                  controller: _diagnosisController,
                  label: 'Diagnosis',
                  icon: Icons.medical_information_rounded,
                ),
                const SizedBox(height: 12),
                _RequiredTextField(
                  controller: _symptomsController,
                  label: 'Symptoms (comma separated)',
                  icon: Icons.sick_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _RequiredTextField(
                  controller: _treatmentController,
                  label: 'Treatment plan',
                  icon: Icons.healing_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RequiredTextField(
                        controller: _medicineController,
                        label: 'Medicine',
                        icon: Icons.medication_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RequiredTextField(
                        controller: _dosageController,
                        label: 'Dosage',
                        icon: Icons.monitor_heart_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _RequiredTextField(
                  controller: _durationController,
                  label: 'Duration',
                  icon: Icons.schedule_rounded,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Additional notes',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickAndUploadAttachment,
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file_rounded),
                  label: Text(
                    _uploading ? 'Uploading...' : 'Upload PDF/Image Attachment',
                  ),
                ),
                if (_attachments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _attachments
                        .map(
                          (url) => Chip(
                            avatar: const Icon(Icons.check_rounded, size: 16),
                            label: Text(
                              'Attachment ${_attachments.indexOf(url) + 1}',
                            ),
                            onDeleted: () =>
                                setState(() => _attachments.remove(url)),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _submitRecord,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving...' : 'Submit Record'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _uploading = true);
    try {
      final url = await CloudinaryService().uploadMedicalRecordAttachment(path);
      setState(() => _attachments.add(url));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attachment upload failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submitRecord() async {
    if (!_formKey.currentState!.validate() || _selectedAppointment == null) {
      return;
    }

    final appointment = _selectedAppointment!;
    final now = DateTime.now();
    final record = MedicalRecordModel(
      id: '',
      appointmentId: appointment.id,
      doctorId: widget.doctor.uid,
      doctorName: 'Dr. vin israel',
      nurseName: 'nurse. wilson',
      patientId: appointment.patientId,
      patientName: appointment.patientName,
      diagnosis: _diagnosisController.text.trim(),
      symptoms: _symptomsController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      treatmentPlan: _treatmentController.text.trim(),
      prescription: [
        PrescriptionItem(
          medicine: _medicineController.text.trim(),
          dosage: _dosageController.text.trim(),
          duration: _durationController.text.trim(),
        ),
      ],
      notes: _notesController.text.trim(),
      attachments: List<String>.from(_attachments),
      createdAt: now,
      updatedAt: now,
      createdBy: widget.doctor.uid,
    );

    setState(() => _saving = true);
    try {
      await ref
          .read(medicalRecordRepositoryProvider)
          .createMedicalRecord(record);
      ref.invalidate(doctorMedicalRecordsProvider(widget.doctor.uid));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Medical record saved.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save record: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _RequiredTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  const _RequiredTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required.';
        }
        return null;
      },
    );
  }
}

class _DoctorSummary extends StatelessWidget {
  final List<MedicalRecordModel> records;

  const _DoctorSummary({required this.records});

  @override
  Widget build(BuildContext context) {
    final prescriptionCount = records.fold<int>(
      0,
      (sum, record) => sum + record.prescription.length,
    );
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Records',
            value: records.length.toString(),
            icon: Icons.folder_shared_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryTile(
            label: 'Prescriptions',
            value: prescriptionCount.toString(),
            icon: Icons.medication_rounded,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primarySurface,
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neutralDark,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.neutralMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoctorRecordCard extends StatelessWidget {
  final MedicalRecordModel record;

  const _DoctorRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM yyyy').format(record.createdAt);
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
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.primarySurface,
                child: Icon(
                  Icons.article_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.patientName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutralDark,
                      ),
                    ),
                    Text(
                      '$date - ${record.diagnosis}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.neutralLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.lock_rounded,
                size: 18,
                color: AppTheme.protectedColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            record.treatmentPlan,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppTheme.neutralMedium,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipText(text: '${record.symptoms.length} symptoms'),
              _ChipText(text: '${record.prescription.length} prescriptions'),
              _ChipText(text: '${record.attachments.length} attachments'),
              _ChipText(text: record.nurseName),
            ],
          ),
          if (record.attachments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: record.attachments.first),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attachment link copied.')),
                  );
                },
                icon: const Icon(Icons.link_rounded, size: 16),
                label: const Text('Copy Attachment Link'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipText extends StatelessWidget {
  final String text;

  const _ChipText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.neutralSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: AppTheme.neutralMedium),
      ),
    );
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppTheme.neutralLight),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.neutralMedium),
          ),
        ],
      ),
    );
  }
}
