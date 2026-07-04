import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/providers/auth_providers.dart';
import '../../../../features/auth/providers/auth_state.dart';

// ── Mock Data ──────────────────────────────────────────────────────────────────

class _LoginRecord {
  final DateTime dateTime;
  final String device;
  final String ip;
  final String location;
  final bool success;

  const _LoginRecord({
    required this.dateTime,
    required this.device,
    required this.ip,
    required this.location,
    required this.success,
  });
}

class _TrustedDevice {
  final String name;
  final String type; // phone, laptop, tablet
  final DateTime lastUsed;
  final String location;

  const _TrustedDevice({
    required this.name,
    required this.type,
    required this.lastUsed,
    required this.location,
  });
}

class _ActivityLog {
  final String action;
  final DateTime timestamp;
  final String details;

  const _ActivityLog({
    required this.action,
    required this.timestamp,
    required this.details,
  });
}

final List<_LoginRecord> _mockLoginHistory = [
  _LoginRecord(
    dateTime: DateTime(2026, 6, 30, 9, 12),
    device: 'Chrome — Windows 11',
    ip: '102.89.34.112',
    location: 'Lagos, Nigeria',
    success: true,
  ),
  _LoginRecord(
    dateTime: DateTime(2026, 6, 29, 22, 45),
    device: 'Safari — iPhone 16',
    ip: '102.89.34.112',
    location: 'Lagos, Nigeria',
    success: true,
  ),
  _LoginRecord(
    dateTime: DateTime(2026, 6, 29, 18, 5),
    device: 'Firefox — Ubuntu 24.04',
    ip: '197.210.55.8',
    location: 'Abuja, Nigeria',
    success: false,
  ),
  _LoginRecord(
    dateTime: DateTime(2026, 6, 28, 8, 30),
    device: 'Chrome — Windows 11',
    ip: '102.89.34.112',
    location: 'Lagos, Nigeria',
    success: true,
  ),
  _LoginRecord(
    dateTime: DateTime(2026, 6, 27, 14, 0),
    device: 'TeleCare App — Android 15',
    ip: '105.112.10.44',
    location: 'Ibadan, Nigeria',
    success: true,
  ),
];

final List<_TrustedDevice> _mockDevices = [
  _TrustedDevice(
    name: 'Dell XPS 15',
    type: 'laptop',
    lastUsed: DateTime(2026, 6, 30, 9, 12),
    location: 'Lagos, Nigeria',
  ),
  _TrustedDevice(
    name: 'iPhone 16 Pro',
    type: 'phone',
    lastUsed: DateTime(2026, 6, 29, 22, 45),
    location: 'Lagos, Nigeria',
  ),
  _TrustedDevice(
    name: 'Samsung Galaxy Tab S10',
    type: 'tablet',
    lastUsed: DateTime(2026, 6, 25, 16, 0),
    location: 'Ibadan, Nigeria',
  ),
];

final List<_ActivityLog> _mockActivity = [
  _ActivityLog(
    action: 'Approved doctor verification',
    timestamp: DateTime(2026, 6, 30, 10, 15),
    details: 'Dr. Emeka Obi — License #MED-2024-0892',
  ),
  _ActivityLog(
    action: 'Updated platform settings',
    timestamp: DateTime(2026, 6, 30, 9, 50),
    details: 'Changed consultation fee cap from ₦15,000 to ₦20,000',
  ),
  _ActivityLog(
    action: 'Exported analytics report',
    timestamp: DateTime(2026, 6, 29, 16, 30),
    details: 'Monthly report — June 2026 (PDF)',
  ),
  _ActivityLog(
    action: 'Disabled user account',
    timestamp: DateTime(2026, 6, 29, 14, 10),
    details: 'User: james.okoro@mail.com — reason: policy violation',
  ),
  _ActivityLog(
    action: 'Initiated manual backup',
    timestamp: DateTime(2026, 6, 29, 11, 0),
    details: 'Full system backup — 1.1 GB completed',
  ),
];

// ── View ────────────────────────────────────────────────────────────────────────

class AdminProfileView extends ConsumerStatefulWidget {
  const AdminProfileView({super.key});

  @override
  ConsumerState<AdminProfileView> createState() => _AdminProfileViewState();
}

class _AdminProfileViewState extends ConsumerState<AdminProfileView> {
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  bool _showCurrentPw = false;
  bool _showNewPw = false;
  bool _showConfirmPw = false;

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  String _fmtDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  IconData _deviceIcon(String type) {
    switch (type) {
      case 'phone':
        return Icons.phone_android_rounded;
      case 'laptop':
        return Icons.laptop_rounded;
      case 'tablet':
        return Icons.tablet_rounded;
      default:
        return Icons.devices_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);

    // Pull admin info from auth state if authenticated
    String adminName = 'Admin User';
    String adminEmail = 'admin@telecare.com';
    if (authState is AuthAuthenticated) {
      adminName = authState.user.fullName.isNotEmpty
          ? authState.user.fullName
          : adminName;
      adminEmail = authState.user.email.isNotEmpty
          ? authState.user.email
          : adminEmail;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Admin Profile',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your profile, security, and devices',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppTheme.neutralMedium),
          ),
          const SizedBox(height: 24),

          // ── Profile Card ──
          _buildProfileCard(adminName, adminEmail),
          const SizedBox(height: 24),

          // ── Change Password ──
          _sectionTitle('Change Password'),
          const SizedBox(height: 10),
          _buildPasswordSection(),
          const SizedBox(height: 24),

          // ── Login History ──
          _sectionTitle('Login History'),
          const SizedBox(height: 10),
          ..._mockLoginHistory.map((r) => _buildLoginTile(r)),
          const SizedBox(height: 24),

          // ── Trusted Devices ──
          _sectionTitle('Trusted Devices'),
          const SizedBox(height: 10),
          ..._mockDevices.map((d) => _buildDeviceTile(d)),
          const SizedBox(height: 24),

          // ── Activity Logs ──
          _sectionTitle('Activity Logs'),
          const SizedBox(height: 10),
          ..._mockActivity.map((a) => _buildActivityTile(a)),

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

  // ── Profile Card ──

  Widget _buildProfileCard(String name, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.neutralSurface),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 42,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 42,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            email,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.neutralMedium,
            ),
          ),
          const SizedBox(height: 10),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Super Admin',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Meta row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_month_rounded,
                  size: 13, color: AppTheme.neutralLight),
              const SizedBox(width: 4),
              Text(
                'Member since ${_fmtDate(DateTime(2025, 1, 15))}',
                style: const TextStyle(
                    fontSize: 11.5, color: AppTheme.neutralLight),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.login_rounded,
                  size: 13, color: AppTheme.neutralLight),
              const SizedBox(width: 4),
              Text(
                'Last login ${_fmtDateTime(DateTime(2026, 6, 30, 9, 12))}',
                style: const TextStyle(
                    fontSize: 11.5, color: AppTheme.neutralLight),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Edit button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit Profile tapped'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Change Password Section ──

  Widget _buildPasswordSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.neutralSurface),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          TextField(
            controller: _currentPwController,
            obscureText: !_showCurrentPw,
            decoration: InputDecoration(
              labelText: 'Current Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_showCurrentPw
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded),
                onPressed: () =>
                    setState(() => _showCurrentPw = !_showCurrentPw),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _newPwController,
            obscureText: !_showNewPw,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                icon: Icon(_showNewPw
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded),
                onPressed: () => setState(() => _showNewPw = !_showNewPw),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmPwController,
            obscureText: !_showConfirmPw,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                icon: Icon(_showConfirmPw
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded),
                onPressed: () =>
                    setState(() => _showConfirmPw = !_showConfirmPw),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password updated successfully!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                _currentPwController.clear();
                _newPwController.clear();
                _confirmPwController.clear();
              },
              child: const Text('Update Password'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Login History Tile ──

  Widget _buildLoginTile(_LoginRecord record) {
    final isSuccess = record.success;
    final statusColor =
        isSuccess ? AppTheme.statusApprovedText : AppTheme.statusRejectedText;
    final statusBg =
        isSuccess ? AppTheme.statusApproved : AppTheme.statusRejected;
    final statusLabel = isSuccess ? 'Success' : 'Failed';

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
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.login_rounded : Icons.block_rounded,
              size: 18,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fmtDateTime(record.dateTime),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neutralDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  record.device,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppTheme.neutralMedium),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      record.ip,
                      style: const TextStyle(
                          fontSize: 10.5, color: AppTheme.neutralLight),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on_outlined,
                        size: 11, color: AppTheme.neutralLight),
                    const SizedBox(width: 2),
                    Text(
                      record.location,
                      style: const TextStyle(
                          fontSize: 10.5, color: AppTheme.neutralLight),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Trusted Device Tile ──

  Widget _buildDeviceTile(_TrustedDevice device) {
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
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _deviceIcon(device.type),
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
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
                      'Last used: ${_fmtDateTime(device.lastUsed)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.neutralLight),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on_outlined,
                        size: 11, color: AppTheme.neutralLight),
                    const SizedBox(width: 2),
                    Text(
                      device.location,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.neutralLight),
                    ),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${device.name} removed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.errorColor),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
            child: const Text(
              'Remove',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Activity Log Tile ──

  Widget _buildActivityTile(_ActivityLog activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.neutralSurface),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded,
                size: 18, color: AppTheme.infoColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.action,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neutralDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  activity.details,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppTheme.neutralMedium),
                ),
                const SizedBox(height: 4),
                Text(
                  _fmtDateTime(activity.timestamp),
                  style: const TextStyle(
                      fontSize: 10.5, color: AppTheme.neutralLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
