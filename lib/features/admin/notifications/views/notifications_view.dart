import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/telecare_ui.dart';

/// Mock sent notification for history tab.
class _MockNotification {
  final String title;
  final String message;
  final String type; // 'Maintenance', 'System Update', 'New Feature', 'Emergency Alert'
  final String recipient;
  final String priority; // 'Normal', 'Important', 'Critical'
  final DateTime sentAt;

  const _MockNotification({
    required this.title,
    required this.message,
    required this.type,
    required this.recipient,
    required this.priority,
    required this.sentAt,
  });
}

class NotificationsView extends ConsumerStatefulWidget {
  const NotificationsView({super.key});

  @override
  ConsumerState<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends ConsumerState<NotificationsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Compose State ─────────────────────────────────────────────────────────
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'Maintenance';
  String _selectedRecipient = 'Everyone';
  String _selectedPriority = 'Normal';

  final List<String> _notificationTypes = [
    'Maintenance',
    'System Update',
    'New Feature',
    'Emergency Alert',
  ];

  final List<String> _recipientOptions = [
    'Everyone',
    'Doctors Only',
    'Patients Only',
    'Specific Users',
  ];

  final List<String> _priorityOptions = ['Normal', 'Important', 'Critical'];

  // ── Mock History ──────────────────────────────────────────────────────────
  final List<_MockNotification> _history = [
    _MockNotification(
      title: 'Scheduled Maintenance Window',
      message:
          'TeleCare will undergo scheduled maintenance on July 5th from 2:00 AM to 4:00 AM WAT. Services may be intermittently unavailable.',
      type: 'Maintenance',
      recipient: 'Everyone',
      priority: 'Important',
      sentAt: DateTime(2026, 6, 30, 10, 0),
    ),
    _MockNotification(
      title: 'App Update v3.2.0 Released',
      message:
          'A new version of TeleCare is now available with improved video call stability and prescription management features.',
      type: 'System Update',
      recipient: 'Everyone',
      priority: 'Normal',
      sentAt: DateTime(2026, 6, 28, 14, 30),
    ),
    _MockNotification(
      title: 'New e-Prescription Module',
      message:
          'Doctors can now issue electronic prescriptions directly through the consultation interface. Check the guide for details.',
      type: 'New Feature',
      recipient: 'Doctors Only',
      priority: 'Normal',
      sentAt: DateTime(2026, 6, 25, 9, 15),
    ),
    _MockNotification(
      title: 'Urgent: Security Patch Applied',
      message:
          'A critical security vulnerability has been patched. All users must re-authenticate on next login for security purposes.',
      type: 'Emergency Alert',
      recipient: 'Everyone',
      priority: 'Critical',
      sentAt: DateTime(2026, 6, 22, 16, 45),
    ),
    _MockNotification(
      title: 'Health Tips Section Now Live',
      message:
          'Patients can now access curated health articles and FAQs under the new Health Content section in the app.',
      type: 'New Feature',
      recipient: 'Patients Only',
      priority: 'Normal',
      sentAt: DateTime(2026, 6, 20, 11, 0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Tab Bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: AppTheme.neutralSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.neutralMedium,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Compose'),
              Tab(text: 'History'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildComposeTab(theme),
              _buildHistoryTab(theme),
            ],
          ),
        ),
      ],
    );
  }

  // ── Compose Tab ───────────────────────────────────────────────────────────
  Widget _buildComposeTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Notification Title',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            cursorColor: TeleCareInputStyles.cursorColor,
            style: TeleCareInputStyles.textStyle,
            decoration: TeleCareInputStyles.decoration(
              hintText: 'Enter notification title...',
            ),
          ),
          const SizedBox(height: 20),

          // Message
          Text(
            'Message',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 5,
            cursorColor: TeleCareInputStyles.cursorColor,
            style: TeleCareInputStyles.textStyle,
            decoration: TeleCareInputStyles.decoration(
              hintText: 'Enter notification message...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),

          // Notification Type Dropdown
          Text(
            'Notification Type',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.primaryColor,
                width: 1.5,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.primaryColor),
                items: _notificationTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(_getTypeIcon(type),
                                  size: 18, color: _getTypeColor(type)),
                              const SizedBox(width: 10),
                              Text(
                                type,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.neutralDark,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedType = val ?? _selectedType),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Recipient Selection
          Text(
            'Recipients',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recipientOptions.map((r) {
              final isSelected = _selectedRecipient == r;
              return ChoiceChip(
                label: Text(r),
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
                    setState(() => _selectedRecipient = r),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Priority Selection
          Text(
            'Priority',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _priorityOptions.map((p) {
              final isSelected = _selectedPriority == p;
              final color = _getPriorityColor(p);
              return ChoiceChip(
                avatar: isSelected
                    ? null
                    : Icon(Icons.circle, size: 10, color: color),
                label: Text(p),
                selected: isSelected,
                backgroundColor: AppTheme.neutralSurface,
                selectedColor: color,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.neutralDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                side: BorderSide.none,
                onSelected: (_) =>
                    setState(() => _selectedPriority = p),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Send Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                if (_titleController.text.isEmpty ||
                    _messageController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in title and message.'),
                      backgroundColor: AppTheme.warningColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification sent successfully!'),
                    backgroundColor: AppTheme.successColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                _titleController.clear();
                _messageController.clear();
                setState(() {
                  _selectedType = 'Maintenance';
                  _selectedRecipient = 'Everyone';
                  _selectedPriority = 'Normal';
                });
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Send Notification'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── History Tab ───────────────────────────────────────────────────────────
  Widget _buildHistoryTab(ThemeData theme) {
    if (_history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_rounded,
                size: 64, color: AppTheme.neutralLight),
            SizedBox(height: 16),
            Text(
              'No notifications sent yet.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.neutralMedium,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) =>
          _buildHistoryCard(_history[index]),
    );
  }

  Widget _buildHistoryCard(_MockNotification notification) {
    final typeColor = _getTypeColor(notification.type);
    final priorityColor = _getPriorityColor(notification.priority);
    final formattedDate =
        '${notification.sentAt.day}/${notification.sentAt.month}/${notification.sentAt.year}'
        '  ${notification.sentAt.hour.toString().padLeft(2, '0')}:${notification.sentAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.neutralSurface, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colored left border
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusMedium),
                  bottomLeft: Radius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Priority
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.neutralDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            notification.priority,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: priorityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Message preview
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutralMedium,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Type badge + Recipient + Date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getTypeIcon(notification.type),
                                  size: 12, color: typeColor),
                              const SizedBox(width: 4),
                              Text(
                                notification.type,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: typeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.people_rounded,
                            size: 12, color: AppTheme.neutralLight),
                        const SizedBox(width: 4),
                        Text(
                          notification.recipient,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.neutralMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppTheme.neutralLight,
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
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color _getTypeColor(String type) {
    switch (type) {
      case 'Maintenance':
        return AppTheme.warningColor;
      case 'System Update':
        return AppTheme.infoColor;
      case 'New Feature':
        return AppTheme.successColor;
      case 'Emergency Alert':
        return AppTheme.errorColor;
      default:
        return AppTheme.neutralMedium;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Maintenance':
        return Icons.build_rounded;
      case 'System Update':
        return Icons.system_update_rounded;
      case 'New Feature':
        return Icons.new_releases_rounded;
      case 'Emergency Alert':
        return Icons.emergency_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Normal':
        return AppTheme.infoColor;
      case 'Important':
        return AppTheme.warningColor;
      case 'Critical':
        return AppTheme.errorColor;
      default:
        return AppTheme.neutralMedium;
    }
  }
}
