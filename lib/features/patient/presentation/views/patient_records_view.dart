import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';

class PatientRecordsView extends ConsumerStatefulWidget {
  final UserModel user;

  const PatientRecordsView({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<PatientRecordsView> createState() => _PatientRecordsViewState();
}

class _PatientRecordsViewState extends ConsumerState<PatientRecordsView> with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  final List<_MockRecord> _records = [
    _MockRecord(
      title: 'Complete Blood Count (CBC)',
      date: 'Jun 18, 2026',
      doctorName: 'Dr. Sarah Chen',
      type: 'Lab Report',
      status: 'Normal',
      statusColor: AppTheme.successColor,
      details: 'All parameters (WBC, RBC, Hemoglobin, Platelets) are within standard clinical ranges.',
    ),
    _MockRecord(
      title: 'Chest X-Ray (AP/Lateral)',
      date: 'May 30, 2026',
      doctorName: 'Dr. Marcus Webb',
      type: 'Imaging',
      status: 'Reviewed',
      statusColor: AppTheme.infoColor,
      details: 'No acute cardiopulmonary abnormalities or active lung lesions noted.',
    ),
    _MockRecord(
      title: 'Echocardiogram Panel',
      date: 'Apr 14, 2026',
      doctorName: 'Dr. Sarah Chen',
      type: 'Cardiology',
      status: 'Attention',
      statusColor: AppTheme.warningColor,
      details: 'Mild mitral valve regurgitation detected. Recommended repeat scanning in 6 months.',
    ),
    _MockRecord(
      title: 'Thyroid Stimulating Hormone (TSH)',
      date: 'Mar 02, 2026',
      doctorName: 'Dr. Priya Nair',
      type: 'Lab Report',
      status: 'Normal',
      statusColor: AppTheme.successColor,
      details: 'TSH level at 2.4 mIU/L, showing well-managed hormonal response.',
    ),
  ];

  final List<_MockPrescription> _prescriptions = [
    _MockPrescription(
      drugName: 'Lisinopril 10mg',
      instruction: 'Take 1 tablet daily in the morning',
      doctorName: 'Dr. Sarah Chen',
      date: 'Jun 10, 2026',
      refillsRemaining: 2,
      active: true,
    ),
    _MockPrescription(
      drugName: 'Amoxicillin 500mg',
      instruction: 'Take 1 capsule every 8 hours for 7 days',
      doctorName: 'Dr. Priya Nair',
      date: 'May 12, 2026',
      refillsRemaining: 0,
      active: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Medical Records'),
              Tab(text: 'Prescriptions'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _subTabController,
        children: [
          // Medical Records Tab
          ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _records.length,
            itemBuilder: (context, index) {
              final rec = _records[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: ExpansionTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: rec.statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.article_outlined, color: rec.statusColor, size: 20),
                  ),
                  title: Text(
                    rec.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutralDark,
                    ),
                  ),
                  subtitle: Text(
                    '${rec.type} · ${rec.date}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.neutralLight),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: rec.statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rec.status,
                      style: TextStyle(
                        color: rec.statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 16),
                          Row(
                            children: [
                              const Text('Attending Physician: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.neutralMedium)),
                              Text(rec.doctorName, style: const TextStyle(fontSize: 12, color: AppTheme.neutralDark)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text('Detailed Findings:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.neutralMedium)),
                          const SizedBox(height: 4),
                          Text(
                            rec.details,
                            style: const TextStyle(fontSize: 12, color: AppTheme.neutralDark, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Downloading PDF report...')),
                                  );
                                },
                                icon: const Icon(Icons.download_rounded, size: 14),
                                label: const Text('Download PDF', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Prescriptions Tab
          ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _prescriptions.length,
            itemBuilder: (context, index) {
              final rx = _prescriptions[index];
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
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: rx.active
                                    ? AppTheme.primarySurface
                                    : AppTheme.neutralSurface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.medication_rounded,
                                color: rx.active ? AppTheme.primaryColor : AppTheme.neutralLight,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rx.drugName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.neutralDark,
                                  ),
                                ),
                                Text(
                                  'Prescribed on ${rx.date}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.neutralLight),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: rx.active
                                ? AppTheme.successColor.withValues(alpha: 0.1)
                                : AppTheme.neutralSurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rx.active ? 'ACTIVE' : 'EXPIRED',
                            style: TextStyle(
                              color: rx.active ? AppTheme.successColor : AppTheme.neutralLight,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.neutralBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Directions: ${rx.instruction}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.neutralDark,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'By ${rx.doctorName} · ${rx.refillsRemaining} refills left',
                          style: const TextStyle(fontSize: 11, color: AppTheme.neutralMedium),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sharing prescription details...')),
                            );
                          },
                          icon: const Icon(Icons.share_rounded, size: 14),
                          label: const Text('Share Rx', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MockRecord {
  final String title;
  final String date;
  final String doctorName;
  final String type;
  final String status;
  final Color statusColor;
  final String details;

  _MockRecord({
    required this.title,
    required this.date,
    required this.doctorName,
    required this.type,
    required this.status,
    required this.statusColor,
    required this.details,
  });
}

class _MockPrescription {
  final String drugName;
  final String instruction;
  final String doctorName;
  final String date;
  final int refillsRemaining;
  final bool active;

  _MockPrescription({
    required this.drugName,
    required this.instruction,
    required this.doctorName,
    required this.date,
    required this.refillsRemaining,
    required this.active,
  });
}
