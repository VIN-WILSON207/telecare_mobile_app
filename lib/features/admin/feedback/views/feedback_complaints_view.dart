import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

// ── Mock Data ──────────────────────────────────────────────────────────────────

class _Complaint {
  final String id;
  final String userName;
  final String userEmail;
  final String category;
  final String description;
  final String priority; // Critical, High, Medium, Low
  final String status; // Open, In Progress, Resolved, Closed
  final DateTime createdAt;
  final DateTime updatedAt;

  const _Complaint({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.category,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
}

final List<_Complaint> _mockComplaints = [
  _Complaint(
    id: 'CMP-001',
    userName: 'Amina Bello',
    userEmail: 'amina.bello@mail.com',
    category: 'Abuse Report',
    description:
        'Doctor was verbally abusive during the consultation. Patient felt intimidated and wants the matter investigated urgently.',
    priority: 'Critical',
    status: 'Open',
    createdAt: DateTime(2026, 6, 28, 9, 15),
    updatedAt: DateTime(2026, 6, 28, 9, 15),
  ),
  _Complaint(
    id: 'CMP-002',
    userName: 'David Okonkwo',
    userEmail: 'david.okonkwo@mail.com',
    category: 'Payment Issue',
    description:
        'Double charged for a single teleconsultation session. Transaction refs: TXN-98271 and TXN-98272. Requesting immediate refund.',
    priority: 'High',
    status: 'In Progress',
    createdAt: DateTime(2026, 6, 27, 14, 30),
    updatedAt: DateTime(2026, 6, 28, 11, 45),
  ),
  _Complaint(
    id: 'CMP-003',
    userName: 'Fatima Yusuf',
    userEmail: 'fatima.yusuf@mail.com',
    category: 'Technical Issue',
    description:
        'Video call drops every 2-3 minutes during consultations. Tried on both WiFi and mobile data. Issue persists across multiple sessions.',
    priority: 'Medium',
    status: 'In Progress',
    createdAt: DateTime(2026, 6, 25, 16, 0),
    updatedAt: DateTime(2026, 6, 27, 10, 20),
  ),
  _Complaint(
    id: 'CMP-004',
    userName: 'Chidi Eze',
    userEmail: 'chidi.eze@mail.com',
    category: 'Doctor Complaint',
    description:
        'Doctor did not show up for scheduled appointment. No cancellation notice was sent. Waited for 30 minutes before giving up.',
    priority: 'High',
    status: 'Resolved',
    createdAt: DateTime(2026, 6, 20, 8, 0),
    updatedAt: DateTime(2026, 6, 24, 15, 30),
  ),
  _Complaint(
    id: 'CMP-005',
    userName: 'Grace Adeyemi',
    userEmail: 'grace.adeyemi@mail.com',
    category: 'Technical Issue',
    description:
        'Unable to upload medical documents. The upload spinner runs indefinitely and the file never attaches to the consultation.',
    priority: 'Low',
    status: 'Closed',
    createdAt: DateTime(2026, 6, 15, 11, 0),
    updatedAt: DateTime(2026, 6, 18, 9, 45),
  ),
];

// ── View ────────────────────────────────────────────────────────────────────────

class FeedbackComplaintsView extends ConsumerStatefulWidget {
  const FeedbackComplaintsView({super.key});

  @override
  ConsumerState<FeedbackComplaintsView> createState() =>
      _FeedbackComplaintsViewState();
}

class _FeedbackComplaintsViewState
    extends ConsumerState<FeedbackComplaintsView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedCategory = 'All';

  static const _statuses = [
    'All',
    'Open',
    'In Progress',
    'Resolved',
    'Closed',
  ];
  static const _categories = [
    'All',
    'Doctor Complaint',
    'Technical Issue',
    'Payment Issue',
    'Abuse Report',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ──

  List<_Complaint> get _filteredComplaints {
    final query = _searchQuery.toLowerCase();
    return _mockComplaints.where((c) {
      final matchesSearch = c.userName.toLowerCase().contains(query) ||
          c.userEmail.toLowerCase().contains(query) ||
          c.description.toLowerCase().contains(query) ||
          c.id.toLowerCase().contains(query);
      final matchesStatus =
          _selectedStatus == 'All' || c.status == _selectedStatus;
      final matchesCategory =
          _selectedCategory == 'All' || c.category == _selectedCategory;
      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return AppTheme.errorColor;
      case 'High':
        return AppTheme.warningColor;
      case 'Medium':
        return AppTheme.infoColor;
      case 'Low':
        return AppTheme.neutralMedium;
      default:
        return AppTheme.neutralLight;
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'Open':
        return AppTheme.statusRejected;
      case 'In Progress':
        return AppTheme.statusPending;
      case 'Resolved':
        return AppTheme.statusApproved;
      case 'Closed':
        return AppTheme.statusCompleted;
      default:
        return AppTheme.neutralSurface;
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'Open':
        return AppTheme.statusRejectedText;
      case 'In Progress':
        return AppTheme.statusPendingText;
      case 'Resolved':
        return AppTheme.statusApprovedText;
      case 'Closed':
        return AppTheme.statusCompletedText;
      default:
        return AppTheme.neutralMedium;
    }
  }

  Color _categoryBgColor(String category) {
    switch (category) {
      case 'Doctor Complaint':
        return AppTheme.statusPending;
      case 'Technical Issue':
        return AppTheme.statusCompleted;
      case 'Payment Issue':
        return AppTheme.alertSurface;
      case 'Abuse Report':
        return AppTheme.errorSurface;
      default:
        return AppTheme.neutralSurface;
    }
  }

  Color _categoryTextColor(String category) {
    switch (category) {
      case 'Doctor Complaint':
        return AppTheme.statusPendingText;
      case 'Technical Issue':
        return AppTheme.statusCompletedText;
      case 'Payment Issue':
        return AppTheme.warningColor;
      case 'Abuse Report':
        return AppTheme.statusRejectedText;
      default:
        return AppTheme.neutralMedium;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredComplaints;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header
          Text(
            'Feedback & Complaints',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track and manage user complaints and feedback',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppTheme.neutralMedium),
          ),
          const SizedBox(height: 20),

          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search by user, ID, or description...',
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
          const SizedBox(height: 16),

          // Status filter chips
          Text(
            'Status',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statuses.map((s) {
              final selected = _selectedStatus == s;
              return ChoiceChip(
                label: Text(s),
                selected: selected,
                onSelected: (_) => setState(() => _selectedStatus = s),
                backgroundColor: AppTheme.neutralSurface,
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppTheme.neutralDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Category filter chips
          Text(
            'Category',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((c) {
              final selected = _selectedCategory == c;
              return ChoiceChip(
                label: Text(c),
                selected: selected,
                onSelected: (_) => setState(() => _selectedCategory = c),
                backgroundColor: AppTheme.neutralSurface,
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppTheme.neutralDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Summary stat cards
          _buildSummaryRow(),
          const SizedBox(height: 20),

          // Complaint cards
          if (filtered.isEmpty)
            _buildEmptyState()
          else
            ...filtered.map((c) => _buildComplaintCard(c)),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Summary Row ──

  Widget _buildSummaryRow() {
    const stats = [
      {'label': 'Open', 'count': '12', 'color': AppTheme.errorColor},
      {
        'label': 'In Progress',
        'count': '8',
        'color': AppTheme.warningColor,
      },
      {'label': 'Resolved', 'count': '45', 'color': AppTheme.successColor},
      {'label': 'Closed', 'count': '120', 'color': AppTheme.infoColor},
    ];

    return Row(
      children: stats.map((s) {
        final color = s['color'] as Color;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.neutralSurface),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Text(
                  s['count'] as String,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s['label'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutralMedium,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Empty State ──

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.feedback_outlined, size: 64, color: AppTheme.neutralLight),
            SizedBox(height: 16),
            Text(
              'No complaints match the selected filters.',
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

  // ── Complaint Card ──

  Widget _buildComplaintCard(_Complaint complaint) {
    final priorityCol = _priorityColor(complaint.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.neutralSurface),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored left border
            Container(width: 5, color: priorityCol, height: double.infinity),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ID + badges row
                    Row(
                      children: [
                        Text(
                          complaint.id,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.neutralMedium,
                          ),
                        ),
                        const Spacer(),
                        _buildBadge(
                          complaint.priority,
                          priorityCol.withValues(alpha: 0.12),
                          priorityCol,
                        ),
                        const SizedBox(width: 6),
                        _buildBadge(
                          complaint.status,
                          _statusBgColor(complaint.status),
                          _statusTextColor(complaint.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // User info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: const Icon(Icons.person_outline_rounded,
                              size: 18, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint.userName,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.neutralDark,
                              ),
                            ),
                            Text(
                              complaint.userEmail,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.neutralLight,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _buildBadge(
                          complaint.category,
                          _categoryBgColor(complaint.category),
                          _categoryTextColor(complaint.category),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Description
                    Text(
                      complaint.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.neutralMedium,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Dates
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: AppTheme.neutralLight),
                        const SizedBox(width: 4),
                        Text(
                          'Created: ${_formatDate(complaint.createdAt)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.neutralLight),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.update_rounded,
                            size: 12, color: AppTheme.neutralLight),
                        const SizedBox(width: 4),
                        Text(
                          'Updated: ${_formatDate(complaint.updatedAt)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.neutralLight),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Action buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildActionButton(
                          Icons.person_add_alt_1_rounded,
                          'Assign',
                          AppTheme.infoColor,
                        ),
                        _buildActionButton(
                          Icons.reply_rounded,
                          'Respond',
                          AppTheme.primaryColor,
                        ),
                        _buildActionButton(
                          Icons.check_circle_outline_rounded,
                          'Close',
                          AppTheme.successColor,
                        ),
                        _buildActionButton(
                          Icons.priority_high_rounded,
                          'Escalate',
                          AppTheme.errorColor,
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

  Widget _buildBadge(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label action tapped'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      icon: Icon(icon, size: 14, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }
}
