import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_role.dart';
import '../../providers/admin_providers.dart';

class ReportsView extends ConsumerStatefulWidget {
  const ReportsView({super.key});

  @override
  ConsumerState<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends ConsumerState<ReportsView> {
  String _selectedPeriod = 'Monthly';
  String _selectedExportFormat = 'PDF';

  static const _periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  static const _exportFormats = ['PDF', 'Excel', 'CSV'];

  final List<_ReportType> _reportTypes = [
    _ReportType(
      id: 'users',
      title: 'User Reports',
      description: 'User registrations, roles, account status & demographics',
      icon: Icons.people_alt_rounded,
      color: AppTheme.infoColor,
      lastGenerated: 'Jun 28, 2026',
    ),
    _ReportType(
      id: 'appointments',
      title: 'Appointment Reports',
      description: 'Booking trends, status distribution & scheduling analytics',
      icon: Icons.calendar_month_rounded,
      color: AppTheme.primaryColor,
      lastGenerated: 'Jun 29, 2026',
    ),
    _ReportType(
      id: 'doctor_performance',
      title: 'Doctor Performance',
      description: 'Consultation counts, ratings, response times & activity',
      icon: Icons.medical_services_rounded,
      color: AppTheme.accentColor,
      lastGenerated: 'Jun 27, 2026',
    ),
    _ReportType(
      id: 'patient_satisfaction',
      title: 'Patient Satisfaction',
      description: 'Feedback scores, reviews, NPS & complaint resolution',
      icon: Icons.sentiment_satisfied_alt_rounded,
      color: AppTheme.accentAlt,
      lastGenerated: 'Jun 26, 2026',
    ),
    _ReportType(
      id: 'security',
      title: 'Security Reports',
      description: 'Login attempts, suspicious activity, audit trails & access',
      icon: Icons.shield_rounded,
      color: AppTheme.errorColor,
      lastGenerated: 'Jun 30, 2026',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(allUsersProvider);
    final appointmentsAsync = ref.watch(allAppointmentsProvider);
    final verificationsAsync = ref.watch(allVerificationRequestsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: const Icon(Icons.assessment_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Reports',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Generate and export platform analytics reports',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Time Period Selector ──
          const Text(
            'Time Period',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _periods.map((period) {
              final isSelected = _selectedPeriod == period;
              return ChoiceChip(
                label: Text(period),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedPeriod = period),
                backgroundColor: AppTheme.neutralSurface,
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.neutralDark,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.neutralSurface,
                  ),
                ),
                showCheckmark: false,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Export Format Options ──
          const Text(
            'Export Format',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _exportFormats.map((format) {
              final isSelected = _selectedExportFormat == format;
              final IconData icon;
              switch (format) {
                case 'PDF':
                  icon = Icons.picture_as_pdf_rounded;
                  break;
                case 'Excel':
                  icon = Icons.table_chart_rounded;
                  break;
                case 'CSV':
                  icon = Icons.description_rounded;
                  break;
                default:
                  icon = Icons.file_present_rounded;
              }
              return ChoiceChip(
                avatar: Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppTheme.neutralDark,
                ),
                label: Text(format),
                selected: isSelected,
                onSelected: (_) =>
                    setState(() => _selectedExportFormat = format),
                backgroundColor: AppTheme.neutralSurface,
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.neutralDark,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.neutralSurface,
                  ),
                ),
                showCheckmark: false,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // ── Report Type Grid ──
          const Text(
            'Report Types',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select a report to generate and download',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.neutralMedium,
            ),
          ),
          const SizedBox(height: 16),

          // Report cards grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: _reportTypes.length,
            itemBuilder: (context, index) {
              final report = _reportTypes[index];
              return _buildReportTypeCard(context, report);
            },
          ),
          const SizedBox(height: 28),

          // ── Live Data Summary ──
          usersAsync.when(
            data: (users) {
              return appointmentsAsync.when(
                data: (appointments) {
                  return verificationsAsync.when(
                    data: (requests) {
                      final patientsCount = users
                          .where((u) => u.role == UserRole.patient)
                          .length;
                      final doctorsCount =
                          users.where((u) => u.role == UserRole.doctor).length;
                      final completedAppts = appointments
                          .where(
                              (a) => a.status.toLowerCase() == 'completed')
                          .length;

                      return _buildLiveDataSummary(
                        context,
                        totalUsers: users.length,
                        patients: patientsCount,
                        doctors: doctorsCount,
                        totalAppointments: appointments.length,
                        completedConsultations: completedAppts,
                        verificationRequests: requests.length,
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('Error: $e'),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildReportTypeCard(BuildContext context, _ReportType report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.neutralSurface, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: report.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(report.icon, color: report.color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            report.title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.neutralDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            report.description,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppTheme.neutralMedium,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            'Last: ${report.lastGenerated}',
            style: const TextStyle(
              fontSize: 9.5,
              color: AppTheme.neutralLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Generating ${report.title} ($_selectedPeriod, $_selectedExportFormat)...'),
                    backgroundColor: AppTheme.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: report.color,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusSmall),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Generate',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveDataSummary(
    BuildContext context, {
    required int totalUsers,
    required int patients,
    required int doctors,
    required int totalAppointments,
    required int completedConsultations,
    required int verificationRequests,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.neutralSurface, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.data_usage_rounded,
                    color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Live Data Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neutralDark,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded,
                    color: AppTheme.primaryColor, size: 20),
                tooltip: 'Copy Summary',
                onPressed: () {
                  final summary = '''
TELECARE LIVE DATA SUMMARY
Period: $_selectedPeriod | Format: $_selectedExportFormat
Generated: ${DateTime.now().toLocal()}

Total Users: $totalUsers (Patients: $patients, Doctors: $doctors)
Total Appointments: $totalAppointments
Completed Consultations: $completedConsultations
Verification Requests: $verificationRequests
''';
                  Clipboard.setData(ClipboardData(text: summary));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Summary copied to clipboard!'),
                      backgroundColor: AppTheme.successColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDataRow('Total Registered Users', '$totalUsers'),
          _buildDataRow('Patient Accounts', '$patients'),
          _buildDataRow('Doctor Accounts', '$doctors'),
          _buildDataRow('Total Appointments', '$totalAppointments'),
          _buildDataRow('Completed Consultations', '$completedConsultations'),
          _buildDataRow('Verification Requests', '$verificationRequests'),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutralMedium,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neutralDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: AppTheme.neutralSurface, height: 1),
        ],
      ),
    );
  }
}

class _ReportType {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String lastGenerated;

  const _ReportType({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.lastGenerated,
  });
}
