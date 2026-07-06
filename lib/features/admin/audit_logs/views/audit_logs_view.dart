import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/telecare_ui.dart';
import '../../models/audit_log_model.dart';
import '../../providers/admin_providers.dart';

class AuditLogsView extends ConsumerStatefulWidget {
  const AuditLogsView({super.key});

  @override
  ConsumerState<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends ConsumerState<AuditLogsView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedActionType = 'All';
  String _selectedDateRange = 'All';

  static const _actionTypes = [
    'All',
    'Login',
    'User Management',
    'Settings',
    'Security',
    'Data Access',
    'System',
  ];

  static const _dateRanges = ['All', 'Today', 'This Week', 'This Month'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auditLogsAsync = ref.watch(auditLogsProvider);

    return auditLogsAsync.when(
      data: (logs) {
        final filteredLogs = _filterLogs(logs);

        return Column(
          children: [
            // ── Header Section ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.neutralSurface,
                    width: 1.2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryLight,
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: const Icon(Icons.security_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Audit Logs',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.neutralDark,
                              ),
                            ),
                            Text(
                              '${filteredLogs.length} entries found',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.neutralMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Search Bar ──
                  TextField(
                    controller: _searchController,
                    style: TeleCareInputStyles.formTextStyle,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by user, action or details...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.neutralLight,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.neutralLight),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: AppTheme.neutralMedium),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.neutralSurface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Date Range Chips ──
                  const Text(
                    'Date Range',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.neutralMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _dateRanges.map((range) {
                        final isSelected = _selectedDateRange == range;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(range),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedDateRange = range),
                            backgroundColor: AppTheme.neutralSurface,
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.neutralDark,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSmall),
                              side: BorderSide(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.neutralSurface,
                              ),
                            ),
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Action Type Filter Chips ──
                  const Text(
                    'Action Type',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.neutralMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _actionTypes.map((type) {
                        final isSelected = _selectedActionType == type;
                        final chipColor = _getActionTypeColor(type);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedActionType = type),
                            backgroundColor: AppTheme.neutralSurface,
                            selectedColor: chipColor,
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.neutralDark,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSmall),
                              side: BorderSide(
                                color: isSelected
                                    ? chipColor
                                    : AppTheme.neutralSurface,
                              ),
                            ),
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ── Timeline List ──
            Expanded(
              child: filteredLogs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        final isLast = index == filteredLogs.length - 1;
                        return _buildTimelineEntry(context, log, isLast);
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading logs: $e')),
    );
  }

  List<AuditLogModel> _filterLogs(List<AuditLogModel> logs) {
    final now = DateTime.now();
    return logs.where((log) {
      // Search filter
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          log.userName.toLowerCase().contains(query) ||
          log.details.toLowerCase().contains(query) ||
          log.action.toLowerCase().contains(query);
      if (!matchesSearch) return false;

      // Action type filter
      if (_selectedActionType != 'All') {
        final actionCategory = _categorizeAction(log.action);
        if (actionCategory != _selectedActionType) return false;
      }

      // Date range filter
      switch (_selectedDateRange) {
        case 'Today':
          if (log.timestamp.year != now.year ||
              log.timestamp.month != now.month ||
              log.timestamp.day != now.day) {
            return false;
          }
          break;
        case 'This Week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final startOfWeek =
              DateTime(weekStart.year, weekStart.month, weekStart.day);
          if (log.timestamp.isBefore(startOfWeek)) return false;
          break;
        case 'This Month':
          if (log.timestamp.year != now.year ||
              log.timestamp.month != now.month) {
            return false;
          }
          break;
      }

      return true;
    }).toList();
  }

  String _categorizeAction(String action) {
    switch (action.toLowerCase()) {
      case 'login':
        return 'Login';
      case 'registration':
      case 'doctor_approval':
      case 'doctor_rejection':
      case 'profile_update':
        return 'User Management';
      case 'settings_update':
        return 'Settings';
      case 'security_alert':
      case 'password_change':
        return 'Security';
      case 'data_export':
      case 'data_access':
        return 'Data Access';
      default:
        return 'System';
    }
  }

  Widget _buildTimelineEntry(
      BuildContext context, AuditLogModel log, bool isLast) {
    final date = log.timestamp;
    final formattedTime =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final formattedDate = '${date.day}/${date.month}/${date.year}';
    final actionColor = _getActionColor(log.action);
    final actionCategory = _categorizeAction(log.action);

    // Mock IP address from hash of log id
    final ipHash = log.id.hashCode.abs();
    final mockIp =
        '${(ipHash % 200) + 10}.${(ipHash ~/ 3) % 256}.${(ipHash ~/ 7) % 256}.${(ipHash ~/ 11) % 256}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline Column ──
          SizedBox(
            width: 36,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: actionColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: actionColor.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppTheme.neutralSurface,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Log Entry Card ──
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusMedium),
                border:
                    Border.all(color: AppTheme.neutralSurface, width: 1.1),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timestamp row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 12, color: AppTheme.neutralLight),
                          const SizedBox(width: 4),
                          Text(
                            '$formattedTime • $formattedDate',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.neutralLight,
                            ),
                          ),
                        ],
                      ),
                      // Action type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: actionColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          actionCategory,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: actionColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Details
                  Text(
                    log.details,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.neutralDark,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // User and action row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.neutralSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline_rounded,
                            size: 12, color: AppTheme.neutralMedium),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        log.userName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.neutralMedium,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: actionColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.action.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: actionColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // IP Address row
                  Row(
                    children: [
                      const Icon(Icons.language_rounded,
                          size: 12, color: AppTheme.neutralLight),
                      const SizedBox(width: 4),
                      Text(
                        'IP: $mockIp',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.neutralLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.neutralSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_turned_in_rounded,
                    size: 48, color: AppTheme.neutralLight),
              ),
              const SizedBox(height: 16),
              const Text(
                'No audit logs found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neutralMedium,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try adjusting your filters or search query',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutralLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getActionTypeColor(String type) {
    switch (type) {
      case 'Login':
        return AppTheme.infoColor;
      case 'User Management':
        return AppTheme.primaryColor;
      case 'Settings':
        return AppTheme.warningColor;
      case 'Security':
        return AppTheme.errorColor;
      case 'Data Access':
        return AppTheme.accentColor;
      case 'System':
        return AppTheme.neutralMedium;
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'login':
        return AppTheme.infoColor;
      case 'registration':
        return AppTheme.successColor;
      case 'doctor_approval':
        return AppTheme.primaryColor;
      case 'doctor_rejection':
        return AppTheme.errorColor;
      case 'appointment_creation':
        return AppTheme.accentColor;
      case 'appointment_cancellation':
        return AppTheme.errorColor;
      case 'profile_update':
        return AppTheme.accentAlt;
      case 'security_alert':
      case 'password_change':
        return AppTheme.errorColor;
      case 'settings_update':
        return AppTheme.warningColor;
      case 'data_export':
      case 'data_access':
        return AppTheme.accentColor;
      default:
        return AppTheme.neutralMedium;
    }
  }
}
