import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_providers.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  // Interface
  bool _darkMode = false;
  String _selectedLanguage = 'English';

  // Security
  bool _twoFactorAuth = true;
  bool _deviceTrust = false;

  // Notifications
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;
  String _notificationFrequency = 'Instant';

  // Section expansion state
  bool _generalExpanded = true;
  bool _securityExpanded = false;
  bool _notificationExpanded = false;
  bool _systemExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: const Icon(Icons.settings_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Settings',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage application configuration and preferences',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ══════════════════════════════════════════
          //  SECTION 1: General Settings
          // ══════════════════════════════════════════
          _buildExpandableSection(
            icon: Icons.tune_rounded,
            title: 'General Settings',
            subtitle: 'Application identity and contact info',
            color: AppTheme.primaryColor,
            isExpanded: _generalExpanded,
            onToggle: () =>
                setState(() => _generalExpanded = !_generalExpanded),
            children: [
              _buildInfoListTile(
                icon: Icons.image_rounded,
                title: 'Logo',
                value: 'default_logo.png',
                onEdit: () => _showEditSnackBar('Logo'),
              ),
              const Divider(height: 1),
              _buildInfoListTile(
                icon: Icons.apps_rounded,
                title: 'App Name',
                value: 'TeleCare',
                onEdit: () => _showEditSnackBar('App Name'),
              ),
              const Divider(height: 1),
              _buildInfoListTile(
                icon: Icons.email_rounded,
                title: 'Contact Email',
                value: 'admin@telecare.com',
                onEdit: () => _showEditSnackBar('Contact Email'),
              ),
              const Divider(height: 1),
              _buildInfoListTile(
                icon: Icons.phone_rounded,
                title: 'Support Number',
                value: '+234-800-TELECARE',
                onEdit: () => _showEditSnackBar('Support Number'),
              ),
              const Divider(height: 1),
              _buildInfoListTile(
                icon: Icons.privacy_tip_rounded,
                title: 'Privacy Policy',
                value: 'View Document',
                valueColor: AppTheme.infoColor,
                onEdit: () => _showEditSnackBar('Privacy Policy'),
              ),
              const Divider(height: 1),
              _buildInfoListTile(
                icon: Icons.description_rounded,
                title: 'Terms of Service',
                value: 'View Document',
                valueColor: AppTheme.infoColor,
                onEdit: () => _showEditSnackBar('Terms of Service'),
              ),
              const Divider(height: 1),
              // Interface
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.dark_mode_rounded,
                      color: AppTheme.neutralMedium, size: 18),
                ),
                title: const Text(
                  'Dark Theme Mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutralDark,
                  ),
                ),
                subtitle: const Text('Render app in dark color palette'),
                value: _darkMode,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (val) {
                  setState(() => _darkMode = val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Theme updated to ${val ? "Dark Mode" : "Light Mode"}'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.language_rounded,
                      color: AppTheme.neutralMedium, size: 18),
                ),
                title: const Text(
                  'Application Language',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutralDark,
                  ),
                ),
                subtitle: Text('Current: $_selectedLanguage'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppTheme.neutralLight),
                onTap: () => _showLanguageSelector(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ══════════════════════════════════════════
          //  SECTION 2: Security Settings
          // ══════════════════════════════════════════
          _buildExpandableSection(
            icon: Icons.shield_rounded,
            title: 'Security Settings',
            subtitle: 'Authentication, encryption and access control',
            color: AppTheme.errorColor,
            isExpanded: _securityExpanded,
            onToggle: () =>
                setState(() => _securityExpanded = !_securityExpanded),
            children: [
              _buildInfoListTile(
                icon: Icons.password_rounded,
                title: 'Password Policy',
                value: 'Strong (8+ chars, uppercase, number, symbol)',
                onEdit: () => _showEditSnackBar('Password Policy'),
              ),
              const Divider(height: 1),
              _buildInfoListTile(
                icon: Icons.timer_rounded,
                title: 'Session Timeout',
                value: '30 minutes',
                onEdit: () => _showEditSnackBar('Session Timeout'),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.phonelink_lock_rounded,
                      color: AppTheme.neutralMedium, size: 18),
                ),
                title: const Text(
                  'Two-Factor Authentication',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutralDark,
                  ),
                ),
                subtitle: Text(_twoFactorAuth ? 'Enabled' : 'Disabled'),
                value: _twoFactorAuth,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (val) => setState(() => _twoFactorAuth = val),
              ),
              const Divider(height: 1),
              _buildInfoListTile(
                icon: Icons.fingerprint_rounded,
                title: 'Biometric Requirement',
                value: 'Optional',
                onEdit: () => _showEditSnackBar('Biometric Requirement'),
              ),
              const Divider(height: 1),
              _buildInfoListTile(
                icon: Icons.block_rounded,
                title: 'Maximum Login Attempts',
                value: '5',
                onEdit: () => _showEditSnackBar('Maximum Login Attempts'),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.devices_rounded,
                      color: AppTheme.neutralMedium, size: 18),
                ),
                title: const Text(
                  'Device Trust',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutralDark,
                  ),
                ),
                subtitle:
                    Text(_deviceTrust ? 'Trusted devices only' : 'Disabled'),
                value: _deviceTrust,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (val) => setState(() => _deviceTrust = val),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: AppTheme.neutralMedium, size: 18),
                ),
                title: const Text(
                  'Encryption Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutralDark,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'AES-256 Active',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.vpn_key_rounded,
                      color: AppTheme.neutralMedium, size: 18),
                ),
                title: const Text(
                  'API Key Management',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutralDark,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Opening API Key Manager...'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primarySurface,
                    foregroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                  child: const Text(
                    'Manage Keys',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ══════════════════════════════════════════
          //  SECTION 3: Notification Settings
          // ══════════════════════════════════════════
          _buildExpandableSection(
            icon: Icons.notifications_active_rounded,
            title: 'Notification Settings',
            subtitle: 'Alert channels and delivery preferences',
            color: AppTheme.warningColor,
            isExpanded: _notificationExpanded,
            onToggle: () =>
                setState(() => _notificationExpanded = !_notificationExpanded),
            children: [
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.notifications_rounded,
                      color: AppTheme.neutralMedium, size: 18),
                ),
                title: const Text(
                  'Push Notifications',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutralDark,
                  ),
                ),
                subtitle: const Text(
                    'Receive push alerts for critical admin activities'),
                value: _pushNotifications,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (val) =>
                    setState(() => _pushNotifications = val),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.email_rounded,
                      color: AppTheme.neutralMedium, size: 18),
                ),
                title: const Text(
                  'Email Notifications',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutralDark,
                  ),
                ),
                subtitle:
                    const Text('Receive email summaries and alerts'),
                value: _emailNotifications,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (val) =>
                    setState(() => _emailNotifications = val),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.sms_rounded,
                      color: AppTheme.neutralMedium, size: 18),
                ),
                title: const Text(
                  'SMS Notifications',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutralDark,
                  ),
                ),
                subtitle:
                    const Text('Receive SMS alerts for urgent events'),
                value: _smsNotifications,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (val) =>
                    setState(() => _smsNotifications = val),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.schedule_rounded,
                      color: AppTheme.neutralMedium, size: 18),
                ),
                title: const Text(
                  'Notification Frequency',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutralDark,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralSurface,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                        color: AppTheme.neutralSurface, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _notificationFrequency,
                      isDense: true,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutralDark,
                      ),
                      items: ['Instant', 'Hourly', 'Daily', 'Weekly']
                          .map((freq) => DropdownMenuItem(
                                value: freq,
                                child: Text(freq),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _notificationFrequency = val);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ══════════════════════════════════════════
          //  SECTION 4: System Information
          // ══════════════════════════════════════════
          _buildExpandableSection(
            icon: Icons.info_outline_rounded,
            title: 'System Information',
            subtitle: 'Platform status and version details',
            color: AppTheme.infoColor,
            isExpanded: _systemExpanded,
            onToggle: () =>
                setState(() => _systemExpanded = !_systemExpanded),
            children: [
              _buildSystemInfoTile(
                icon: Icons.numbers_rounded,
                title: 'App Version',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'v2.1.0',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildSystemInfoTile(
                icon: Icons.cloud_done_rounded,
                title: 'Server Status',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Online',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _buildSystemInfoTile(
                icon: Icons.storage_rounded,
                title: 'Database',
                trailing: const Text(
                  'Firestore (Active)',
                  style: TextStyle(
                    color: AppTheme.neutralMedium,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.sd_storage_rounded,
                      color: AppTheme.neutralMedium, size: 18),
                ),
                title: const Text(
                  'Storage Used',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutralDark,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          value: 0.24,
                          color: AppTheme.primaryColor,
                          backgroundColor: AppTheme.neutralSurface,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '2.4 GB / 10 GB',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.neutralMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildSystemInfoTile(
                icon: Icons.update_rounded,
                title: 'Last System Update',
                trailing: const Text(
                  'Jun 28, 2026',
                  style: TextStyle(
                    color: AppTheme.neutralMedium,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildSystemInfoTile(
                icon: Icons.timer_outlined,
                title: 'Uptime',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '99.9%',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _buildSystemInfoTile(
                icon: Icons.code_rounded,
                title: 'Environment Profile',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.statusPending,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'DEV-MOCK-SMS',
                    style: TextStyle(
                      color: AppTheme.statusPendingText,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Logout Action Card ──
          Container(
            decoration: BoxDecoration(
              color: AppTheme.statusRejected,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: const Border.fromBorderSide(
                BorderSide(color: AppTheme.statusRejectedText, width: 1),
              ),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.statusRejectedText.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppTheme.statusRejectedText, size: 20),
              ),
              title: const Text(
                'Log Out Administrative Session',
                style: TextStyle(
                  color: AppTheme.statusRejectedText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: const Text(
                'Closes the active admin dashboard credentials',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppTheme.statusRejectedText),
              onTap: () => _confirmLogout(context),
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // ── Expandable Section Card ──
  Widget _buildExpandableSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.neutralSurface, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Header (tappable)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppTheme.radiusLarge),
              topRight: const Radius.circular(AppTheme.radiusLarge),
              bottomLeft:
                  Radius.circular(isExpanded ? 0 : AppTheme.radiusLarge),
              bottomRight:
                  Radius.circular(isExpanded ? 0 : AppTheme.radiusLarge),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.neutralDark,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.neutralMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.neutralLight),
                  ),
                ],
              ),
            ),
          ),
          // Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(
                  height: 1,
                  color: AppTheme.neutralSurface,
                ),
                ...children,
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // ── Info ListTile with edit icon ──
  Widget _buildInfoListTile({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    required VoidCallback onEdit,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.neutralSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: AppTheme.neutralMedium, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.neutralDark,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 12.5,
          color: valueColor ?? AppTheme.neutralMedium,
          fontWeight:
              valueColor != null ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit_rounded,
            size: 16, color: AppTheme.neutralLight),
        onPressed: onEdit,
        tooltip: 'Edit $title',
      ),
    );
  }

  // ── System Info Tile ──
  Widget _buildSystemInfoTile({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.neutralSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: AppTheme.neutralMedium, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.neutralDark,
        ),
      ),
      trailing: trailing,
    );
  }

  void _showEditSnackBar(String field) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit "$field" — feature coming soon'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Language',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralDark,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...['English', 'French (Français)'].map((lang) {
                return ListTile(
                  title: Text(lang),
                  trailing: _selectedLanguage == lang
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppTheme.primaryColor)
                      : null,
                  onTap: () {
                    setState(() => _selectedLanguage = lang);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Language updated to $lang'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.errorColor),
            SizedBox(width: 10),
            Text('Log Out?'),
          ],
        ),
        content: const Text(
            'Are you sure you want to terminate your administrative dashboard session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.neutralMedium)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
