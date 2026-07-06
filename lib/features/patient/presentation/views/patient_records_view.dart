import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/data/models/user_model.dart';
import '../../../medical_records/data/models/medical_record_model.dart';
import '../../../medical_records/providers/medical_record_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/telecare_ui.dart';

class PatientRecordsView extends ConsumerStatefulWidget {
  final UserModel user;
  final int initialTab;

  const PatientRecordsView({
    super.key,
    required this.user,
    this.initialTab = 0,
  });

  @override
  ConsumerState<PatientRecordsView> createState() => _PatientRecordsViewState();
}

class _PatientRecordsViewState extends ConsumerState<PatientRecordsView>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab < 0
          ? 0
          : widget.initialTab > 1
              ? 1
              : widget.initialTab,
    );
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(
      patientMedicalRecordsProvider(widget.user.uid),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppTheme.cardWhite,
          child: TabBar(
            controller: _subTabController,
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
              Tab(text: 'Medical Records'),
              Tab(text: 'Prescriptions'),
            ],
          ),
        ),
      ),
      body: recordsAsync.when(
        data: (records) {
          final filtered = _filterRecords(records);
          return TabBarView(
            controller: _subTabController,
            children: [
              _RecordsList(
                records: filtered,
                searchController: _searchController,
                emptyMessage: 'No medical records have been shared yet.',
              ),
              _PrescriptionsList(
                records: filtered
                    .where((record) => record.prescription.isNotEmpty)
                    .toList(),
                searchController: _searchController,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _MessageState(
          icon: Icons.error_outline_rounded,
          message: error.toString(),
          color: AppTheme.errorColor,
        ),
      ),
    );
  }

  List<MedicalRecordModel> _filterRecords(List<MedicalRecordModel> records) {
    if (_query.isEmpty) return records;
    return records.where((record) {
      final text = [
        record.diagnosis,
        record.doctorName,
        record.nurseName,
        record.symptoms.join(' '),
        record.treatmentPlan,
        record.prescription.map((item) => item.medicine).join(' '),
      ].join(' ').toLowerCase();
      return text.contains(_query);
    }).toList();
  }
}

class _RecordsList extends StatelessWidget {
  final List<MedicalRecordModel> records;
  final TextEditingController searchController;
  final String emptyMessage;

  const _RecordsList({
    required this.records,
    required this.searchController,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {},
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _SearchField(controller: searchController),
          const SizedBox(height: 14),
          if (records.isEmpty)
            _MessageState(
              icon: Icons.folder_open_rounded,
              message: emptyMessage,
              color: AppTheme.neutralLight,
            )
          else
            ...records.map((record) => _RecordCard(record: record)),
        ],
      ),
    );
  }
}

class _PrescriptionsList extends StatelessWidget {
  final List<MedicalRecordModel> records;
  final TextEditingController searchController;

  const _PrescriptionsList({
    required this.records,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _SearchField(controller: searchController),
        const SizedBox(height: 14),
        if (records.isEmpty)
          const _MessageState(
            icon: Icons.medication_outlined,
            message: 'No prescriptions are available yet.',
            color: AppTheme.neutralLight,
          )
        else
          ...records.expand(
            (record) => record.prescription.map(
              (rx) => _PrescriptionCard(record: record, item: rx),
            ),
          ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TeleCareInputStyles.formTextStyle,
      decoration: InputDecoration(
        hintText: 'Search records, diagnosis, doctor, medicine...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final MedicalRecordModel record;

  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM yyyy').format(record.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.primarySurface,
          child: Icon(Icons.article_outlined, color: AppTheme.primaryColor),
        ),
        title: Text(
          record.diagnosis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.neutralDark,
          ),
        ),
        subtitle: Text(
          '${record.doctorName} - $date',
          style: const TextStyle(fontSize: 11, color: AppTheme.neutralLight),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 20),
                _InfoBlock(
                  label: 'Symptoms',
                  value: record.symptoms.join(', '),
                ),
                _InfoBlock(
                  label: 'Treatment plan',
                  value: record.treatmentPlan,
                ),
                _InfoBlock(label: 'Clinical notes', value: record.notes),
                _InfoBlock(label: 'Nurse', value: record.nurseName),
                if (record.prescription.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Prescription',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutralMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...record.prescription.map(
                    (item) => Text(
                      '${item.medicine}: ${item.dosage} for ${item.duration}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutralDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                if (record.attachments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: record.attachments.map((url) {
                      return OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Attachment link copied.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Attachment'),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final MedicalRecordModel record;
  final PrescriptionItem item;

  const _PrescriptionCard({required this.record, required this.item});

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.primarySurface,
            child: Icon(Icons.medication_rounded, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicine,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.dosage} - ${item.duration}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.neutralMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${record.doctorName} - $date',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.neutralLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.neutralMedium,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.neutralDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _MessageState({
    required this.icon,
    required this.message,
    required this.color,
  });

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
          Icon(icon, size: 42, color: color),
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
