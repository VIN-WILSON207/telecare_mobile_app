import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/telecare_ui.dart';

/// Mock consultation data model for local state.
class _MockConsultation {
  final String id;
  final String doctorName;
  final String patientName;
  final DateTime startTime;
  final int durationMinutes;
  final String connectionStatus; // 'Stable', 'Intermittent', 'Disconnected'
  final String completionStatus; // 'Active', 'Completed', 'Dropped'

  const _MockConsultation({
    required this.id,
    required this.doctorName,
    required this.patientName,
    required this.startTime,
    required this.durationMinutes,
    required this.connectionStatus,
    required this.completionStatus,
  });
}

class ConsultationMonitoringView extends ConsumerStatefulWidget {
  const ConsultationMonitoringView({super.key});

  @override
  ConsumerState<ConsultationMonitoringView> createState() =>
      _ConsultationMonitoringViewState();
}

class _ConsultationMonitoringViewState
    extends ConsumerState<ConsultationMonitoringView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<_MockConsultation> _consultations = [
    _MockConsultation(
      id: 'CONS-20260630-001',
      doctorName: 'Dr. Amara Okafor',
      patientName: 'Chidinma Eze',
      startTime: DateTime(2026, 6, 30, 9, 15),
      durationMinutes: 32,
      connectionStatus: 'Stable',
      completionStatus: 'Active',
    ),
    _MockConsultation(
      id: 'CONS-20260630-002',
      doctorName: 'Dr. Emeka Nwosu',
      patientName: 'Fatima Bello',
      startTime: DateTime(2026, 6, 30, 8, 0),
      durationMinutes: 45,
      connectionStatus: 'Stable',
      completionStatus: 'Completed',
    ),
    _MockConsultation(
      id: 'CONS-20260629-003',
      doctorName: 'Dr. Ngozi Adeyemi',
      patientName: 'Yusuf Ibrahim',
      startTime: DateTime(2026, 6, 29, 14, 30),
      durationMinutes: 12,
      connectionStatus: 'Disconnected',
      completionStatus: 'Dropped',
    ),
    _MockConsultation(
      id: 'CONS-20260629-004',
      doctorName: 'Dr. Chukwuma Obi',
      patientName: 'Blessing Okoro',
      startTime: DateTime(2026, 6, 29, 11, 0),
      durationMinutes: 28,
      connectionStatus: 'Stable',
      completionStatus: 'Completed',
    ),
    _MockConsultation(
      id: 'CONS-20260630-005',
      doctorName: 'Dr. Aisha Mohammed',
      patientName: 'Tunde Adebayo',
      startTime: DateTime(2026, 6, 30, 10, 45),
      durationMinutes: 18,
      connectionStatus: 'Intermittent',
      completionStatus: 'Active',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_MockConsultation> get _filteredConsultations {
    return _consultations.where((c) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = c.doctorName.toLowerCase().contains(query) ||
          c.patientName.toLowerCase().contains(query) ||
          c.id.toLowerCase().contains(query);
      final matchesFilter = _selectedFilter == 'All' ||
          c.completionStatus == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get _activeCount =>
      _consultations.where((c) => c.completionStatus == 'Active').length;

  int get _completedCount =>
      _consultations.where((c) => c.completionStatus == 'Completed').length;

  String get _averageDuration {
    if (_consultations.isEmpty) return '0 min';
    final total =
        _consultations.fold<int>(0, (sum, c) => sum + c.durationMinutes);
    return '${(total / _consultations.length).round()} min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredConsultations;

    return Column(
      children: [
        // Privacy Notice Banner
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.infoColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppTheme.infoColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Privacy Mode: This dashboard shows consultation metadata only. '
                  'No access to medical content, chat messages, or diagnosis details.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.infoColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Summary Stats Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              _buildStatChip(
                icon: Icons.videocam_rounded,
                label: 'Active',
                count: '$_activeCount',
                color: AppTheme.successColor,
              ),
              const SizedBox(width: 10),
              _buildStatChip(
                icon: Icons.check_circle_rounded,
                label: 'Completed',
                count: '$_completedCount',
                color: AppTheme.infoColor,
              ),
              const SizedBox(width: 10),
              _buildStatChip(
                icon: Icons.timer_rounded,
                label: 'Avg Duration',
                count: _averageDuration,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            style: TeleCareInputStyles.formTextStyle,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search by doctor or patient name...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
        ),

        // Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Active', 'Completed', 'Dropped'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    backgroundColor: AppTheme.neutralSurface,
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.neutralDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    side: BorderSide.none,
                    onSelected: (_) =>
                        setState(() => _selectedFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Consultation List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildConsultationCard(filtered[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.neutralMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationCard(_MockConsultation consultation) {
    final statusColor = _getStatusColor(consultation.completionStatus);
    final formattedTime =
        '${consultation.startTime.hour.toString().padLeft(2, '0')}:'
        '${consultation.startTime.minute.toString().padLeft(2, '0')}';
    final formattedDate =
        '${consultation.startTime.day}/${consultation.startTime.month}/${consultation.startTime.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: const BorderSide(color: AppTheme.neutralSurface, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ID + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  consultation.id,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neutralMedium,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    consultation.completionStatus,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Doctor & Patient
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medical_services_rounded,
                      size: 16, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    consultation.doctorName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutralDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      size: 16, color: AppTheme.infoColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    consultation.patientName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.neutralDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Metadata Row
            Row(
              children: [
                _buildMetaItem(
                    Icons.access_time_rounded, '$formattedTime  $formattedDate'),
                const Spacer(),
                _buildMetaItem(
                    Icons.timer_outlined, '${consultation.durationMinutes} min'),
                const Spacer(),
                _buildConnectionBadge(consultation.connectionStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.neutralLight),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppTheme.neutralMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionBadge(String status) {
    final color = status == 'Stable'
        ? AppTheme.successColor
        : status == 'Intermittent'
            ? AppTheme.warningColor
            : AppTheme.errorColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return AppTheme.successColor;
      case 'Completed':
        return AppTheme.infoColor;
      case 'Dropped':
        return AppTheme.errorColor;
      default:
        return AppTheme.neutralMedium;
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_rounded,
                size: 64, color: AppTheme.neutralLight),
            SizedBox(height: 16),
            Text(
              'No consultations match your criteria.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.neutralMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
