import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

class SecurityCenterView extends ConsumerStatefulWidget {
  const SecurityCenterView({super.key});

  @override
  ConsumerState<SecurityCenterView> createState() =>
      _SecurityCenterViewState();
}

class _SecurityCenterViewState extends ConsumerState<SecurityCenterView> {
  // ── Mock Active Sessions ──────────────────────────────────────────────────
  final List<Map<String, String>> _activeSessions = const [
    {
      'user': 'Dr. Amara Okafor',
      'device': 'iPhone 15 Pro',
      'ip': '192.168.1.42',
      'lastActivity': '2 min ago',
      'location': 'Lagos, NG',
    },
    {
      'user': 'Admin Wilson',
      'device': 'Chrome – Windows 11',
      'ip': '10.0.0.15',
      'lastActivity': 'Just now',
      'location': 'Abuja, NG',
    },
    {
      'user': 'Fatima Bello',
      'device': 'Samsung Galaxy S24',
      'ip': '172.16.0.88',
      'lastActivity': '8 min ago',
      'location': 'Kano, NG',
    },
    {
      'user': 'Dr. Chukwuma Obi',
      'device': 'iPad Air M2',
      'ip': '192.168.2.110',
      'lastActivity': '15 min ago',
      'location': 'Port Harcourt, NG',
    },
  ];

  // ── Mock Devices ──────────────────────────────────────────────────────────
  final List<Map<String, String>> _trustedDevices = const [
    {
      'name': 'iPhone 15 Pro',
      'user': 'Dr. Amara Okafor',
      'lastSeen': '2 min ago',
      'status': 'Trusted',
    },
    {
      'name': 'Samsung Galaxy S24',
      'user': 'Fatima Bello',
      'lastSeen': '8 min ago',
      'status': 'Trusted',
    },
    {
      'name': 'Unknown Android Device',
      'user': 'Yusuf Ibrahim',
      'lastSeen': '3 days ago',
      'status': 'Suspicious',
    },
  ];

  // ── Mock Anomaly Alerts ───────────────────────────────────────────────────
  final List<Map<String, String>> _anomalyAlerts = const [
    {
      'title': 'Multiple failed logins from unknown IP',
      'detail': 'IP 203.0.113.45 – 12 attempts in 5 minutes targeting account dr.emeka@telecare.ng',
      'time': '10 min ago',
      'severity': 'High',
    },
    {
      'title': 'New device login from unusual location',
      'detail': 'User fatima.bello logged in from a new device in an unrecognized location (VPN detected)',
      'time': '1 hour ago',
      'severity': 'Medium',
    },
    {
      'title': 'Brute-force pattern detected',
      'detail': 'Rate-limited 23 requests from subnet 198.51.100.0/24',
      'time': '3 hours ago',
      'severity': 'High',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section: Security Overview ───────────────────────────────────
          Text(
            'Security Overview',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _buildStatCard(
                icon: Icons.login_rounded,
                count: '532',
                label: 'Successful Logins',
                accentColor: AppTheme.successColor,
              ),
              _buildStatCard(
                icon: Icons.error_outline_rounded,
                count: '23',
                label: 'Failed Logins',
                accentColor: AppTheme.errorColor,
              ),
              _buildStatCard(
                icon: Icons.block_rounded,
                count: '3',
                label: 'Blocked Accounts',
                accentColor: AppTheme.errorColor,
              ),
              _buildStatCard(
                icon: Icons.devices_other_rounded,
                count: '7',
                label: 'Suspicious Devices',
                accentColor: AppTheme.warningColor,
              ),
              _buildStatCard(
                icon: Icons.refresh_rounded,
                count: '12',
                label: 'Multiple Login Attempts',
                accentColor: AppTheme.warningColor,
              ),
              _buildStatCard(
                icon: Icons.lock_reset_rounded,
                count: '45',
                label: 'Password Resets',
                accentColor: AppTheme.infoColor,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Section: Active Sessions ────────────────────────────────────
          Text(
            'Active Sessions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 12),
          ..._activeSessions.map((s) => _buildSessionCard(s)),
          const SizedBox(height: 28),

          // ── Section: Security Policies ──────────────────────────────────
          Text(
            'Security Policies',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              side: const BorderSide(color: AppTheme.neutralSurface, width: 1.2),
            ),
            child: Column(
              children: [
                _buildPolicyRow(
                    Icons.password_rounded, 'Password Policy', 'Enabled', true),
                const Divider(height: 1),
                _buildPolicyRow(
                    Icons.timer_outlined, 'Session Timeout', '30 min', true),
                const Divider(height: 1),
                _buildPolicyRow(
                    Icons.security_rounded, 'Two-Factor Auth (2FA)', 'Enabled', true),
                const Divider(height: 1),
                _buildPolicyRow(
                    Icons.fingerprint_rounded, 'Biometric Login', 'Optional', false),
                const Divider(height: 1),
                _buildPolicyRow(
                    Icons.pin_rounded, 'Max Login Attempts', '5', true),
                const Divider(height: 1),
                _buildPolicyRow(
                    Icons.verified_user_rounded, 'Device Trust', 'Enabled', true),
                const Divider(height: 1),
                _buildPolicyRow(
                    Icons.enhanced_encryption_rounded, 'Encryption', 'AES-256', true),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Section: Device Management ──────────────────────────────────
          Text(
            'Device Management',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 12),
          ..._trustedDevices.map((d) => _buildDeviceCard(d)),
          const SizedBox(height: 28),

          // ── Section: IP / Device Anomaly Alerts ─────────────────────────
          Text(
            'Anomaly Alerts',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 12),
          ..._anomalyAlerts.map((a) => _buildAnomalyCard(a)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Stat Card ───────────────────────────────────────────────────────────────
  Widget _buildStatCard({
    required IconData icon,
    required String count,
    required String label,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const Spacer(),
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.neutralMedium,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Session Card ────────────────────────────────────────────────────────────
  Widget _buildSessionCard(Map<String, String> session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: const BorderSide(color: AppTheme.neutralSurface, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.circle, color: AppTheme.successColor, size: 10),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session['user']!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.neutralDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session['device']}  •  ${session['ip']}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.neutralMedium,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${session['location']}  •  ${session['lastActivity']}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.neutralLight,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: AppTheme.errorColor, size: 20),
              tooltip: 'Revoke session',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Session for ${session['user']} revoked.'),
                    backgroundColor: AppTheme.errorColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Policy Row ──────────────────────────────────────────────────────────────
  Widget _buildPolicyRow(
      IconData icon, String label, String value, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutralDark,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.successColor.withValues(alpha: 0.1)
                  : AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? AppTheme.successColor
                    : AppTheme.warningColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Device Card ─────────────────────────────────────────────────────────────
  Widget _buildDeviceCard(Map<String, String> device) {
    final isSuspicious = device['status'] == 'Suspicious';
    final statusColor =
        isSuspicious ? AppTheme.warningColor : AppTheme.successColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: isSuspicious
              ? AppTheme.warningColor.withValues(alpha: 0.4)
              : AppTheme.neutralSurface,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                isSuspicious
                    ? Icons.warning_amber_rounded
                    : Icons.phone_android_rounded,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device['name']!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.neutralDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${device['user']}  •  Last seen: ${device['lastSeen']}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.neutralMedium,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                device['status']!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Anomaly Alert Card ──────────────────────────────────────────────────────
  Widget _buildAnomalyCard(Map<String, String> alert) {
    final isHigh = alert['severity'] == 'High';
    final severityColor =
        isHigh ? AppTheme.errorColor : AppTheme.warningColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: severityColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      color: severityColor.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_rounded, color: severityColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert['title']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.neutralDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          alert['severity']!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: severityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alert['detail']!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutralMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert['time']!,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.neutralLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
