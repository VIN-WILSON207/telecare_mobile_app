import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

// ── Mock Data ──────────────────────────────────────────────────────────────────

class _BackupRecord {
  final DateTime timestamp;
  final String size;
  final String type; // Auto / Manual
  final String status; // Completed / Failed

  const _BackupRecord({
    required this.timestamp,
    required this.size,
    required this.type,
    required this.status,
  });
}

class _RestorePoint {
  final DateTime date;
  final String description;
  final String size;

  const _RestorePoint({
    required this.date,
    required this.description,
    required this.size,
  });
}

final List<_BackupRecord> _mockBackups = [
  _BackupRecord(
    timestamp: DateTime(2026, 6, 30, 3, 0),
    size: '1.2 GB',
    type: 'Auto',
    status: 'Completed',
  ),
  _BackupRecord(
    timestamp: DateTime(2026, 6, 29, 14, 22),
    size: '1.1 GB',
    type: 'Manual',
    status: 'Completed',
  ),
  _BackupRecord(
    timestamp: DateTime(2026, 6, 28, 3, 0),
    size: '1.2 GB',
    type: 'Auto',
    status: 'Failed',
  ),
  _BackupRecord(
    timestamp: DateTime(2026, 6, 27, 3, 0),
    size: '1.1 GB',
    type: 'Auto',
    status: 'Completed',
  ),
  _BackupRecord(
    timestamp: DateTime(2026, 6, 25, 10, 45),
    size: '1.0 GB',
    type: 'Manual',
    status: 'Completed',
  ),
];

final List<_RestorePoint> _mockRestorePoints = [
  _RestorePoint(
    date: DateTime(2026, 6, 30, 3, 0),
    description: 'Full system backup — daily automated',
    size: '1.2 GB',
  ),
  _RestorePoint(
    date: DateTime(2026, 6, 29, 14, 22),
    description: 'Pre-migration manual snapshot',
    size: '1.1 GB',
  ),
  _RestorePoint(
    date: DateTime(2026, 6, 25, 10, 45),
    description: 'Post-update verification backup',
    size: '1.0 GB',
  ),
];

// ── View ────────────────────────────────────────────────────────────────────────

class BackupRecoveryView extends ConsumerStatefulWidget {
  const BackupRecoveryView({super.key});

  @override
  ConsumerState<BackupRecoveryView> createState() => _BackupRecoveryViewState();
}

class _BackupRecoveryViewState extends ConsumerState<BackupRecoveryView> {
  bool _autoBackupEnabled = true;
  String _backupFrequency = 'Daily';

  String _fmtDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Backup & Recovery',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage data backups, restore points, and cloud sync',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppTheme.neutralMedium),
          ),
          const SizedBox(height: 24),

          // ── Quick Actions ──
          _sectionTitle('Quick Actions'),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildQuickAction(
                Icons.backup_rounded,
                'Backup Now',
                AppTheme.primaryColor,
              ),
              const SizedBox(width: 10),
              _buildQuickAction(
                Icons.restore_rounded,
                'Restore',
                AppTheme.infoColor,
              ),
              const SizedBox(width: 10),
              _buildQuickAction(
                Icons.download_rounded,
                'Download\nBackup',
                AppTheme.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Automatic Backup Settings ──
          _sectionTitle('Automatic Backup'),
          const SizedBox(height: 10),
          _buildCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Enable Automatic Backup',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutralDark,
                    ),
                  ),
                  subtitle: const Text(
                    'Automatically back up system data on schedule',
                    style: TextStyle(fontSize: 12, color: AppTheme.neutralLight),
                  ),
                  value: _autoBackupEnabled,
                  activeThumbColor: AppTheme.primaryColor,
                  onChanged: (val) => setState(() => _autoBackupEnabled = val),
                ),
                const Divider(),
                Row(
                  children: [
                    const Text(
                      'Frequency',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutralDark,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.neutralSurface,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _backupFrequency,
                          items: ['Daily', 'Weekly', 'Monthly']
                              .map((f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(
                                      f,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _backupFrequency = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppTheme.neutralLight),
                    const SizedBox(width: 6),
                    Text(
                      'Last auto-backup: ${_fmtDateTime(DateTime(2026, 6, 30, 3, 0))}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.neutralMedium),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Cloud Backup Status ──
          _sectionTitle('Cloud Backup Status'),
          const SizedBox(height: 10),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status row
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Connected',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _cloudInfoRow('Provider', 'Google Cloud'),
                const SizedBox(height: 8),
                _cloudInfoRow(
                    'Last Sync', _fmtDateTime(DateTime(2026, 6, 30, 3, 5))),
                const SizedBox(height: 8),
                _cloudInfoRow('Storage Used', '2.4 GB / 10 GB'),
                const SizedBox(height: 10),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.24,
                    minHeight: 8,
                    backgroundColor: AppTheme.neutralSurface,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '24% used',
                    style:
                        TextStyle(fontSize: 11, color: AppTheme.neutralLight),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Backup History ──
          _sectionTitle('Backup History'),
          const SizedBox(height: 10),
          ..._mockBackups.map((b) => _buildBackupHistoryTile(b)),
          const SizedBox(height: 24),

          // ── Restore Points ──
          _sectionTitle('Restore Points'),
          const SizedBox(height: 10),

          // Warning banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.alertSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                  color: AppTheme.warningColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppTheme.warningColor, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Restoring a backup will overwrite all current data. '
                    'This action cannot be undone.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutralDark,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._mockRestorePoints.map((rp) => _buildRestorePointTile(rp)),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Section Title ──

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.neutralMedium,
        letterSpacing: 0.3,
      ),
    );
  }

  // ── Quick Action Card ──

  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${label.replaceAll('\n', ' ')} tapped'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.neutralSurface),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.neutralDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared Card Wrapper ──

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.neutralSurface),
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );
  }

  // ── Cloud Info Row ──

  Widget _cloudInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppTheme.neutralMedium,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.neutralDark,
          ),
        ),
      ],
    );
  }

  // ── Backup History Tile ──

  Widget _buildBackupHistoryTile(_BackupRecord backup) {
    final isCompleted = backup.status == 'Completed';
    final statusColor =
        isCompleted ? AppTheme.statusApprovedText : AppTheme.statusRejectedText;
    final statusBg =
        isCompleted ? AppTheme.statusApproved : AppTheme.statusRejected;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.neutralSurface),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (backup.type == 'Auto'
                      ? AppTheme.infoColor
                      : AppTheme.primaryColor)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              backup.type == 'Auto'
                  ? Icons.autorenew_rounded
                  : Icons.touch_app_rounded,
              size: 18,
              color: backup.type == 'Auto'
                  ? AppTheme.infoColor
                  : AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fmtDateTime(backup.timestamp),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neutralDark,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      backup.size,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppTheme.neutralLight),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.neutralSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        backup.type,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.neutralMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        backup.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isCompleted)
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Downloading backup...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded,
                  size: 20, color: AppTheme.primaryColor),
              tooltip: 'Download',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  // ── Restore Point Tile ──

  Widget _buildRestorePointTile(_RestorePoint rp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.neutralSurface),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restore_rounded,
                size: 18, color: AppTheme.accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fmtDateTime(rp.date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neutralDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rp.description,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppTheme.neutralMedium),
                ),
                const SizedBox(height: 2),
                Text(
                  rp.size,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.neutralLight),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Restore initiated...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryColor),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
            child: const Text(
              'Restore',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
