import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../core/theme/app_theme.dart';

class PatientProfileView extends ConsumerStatefulWidget {
  final UserModel user;

  const PatientProfileView({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<PatientProfileView> createState() => _PatientProfileViewState();
}

class _PatientProfileViewState extends ConsumerState<PatientProfileView> {
  bool _isEnglish = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primarySurface,
                      backgroundImage: widget.user.profileImage != null && widget.user.profileImage!.isNotEmpty
                          ? NetworkImage(widget.user.profileImage!)
                          : null,
                      child: widget.user.profileImage == null || widget.user.profileImage!.isEmpty
                          ? Text(
                              widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : 'P',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.user.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralDark,
                  ),
                ),
                Text(
                  widget.user.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.neutralMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PATIENT ACCOUNT',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Personal Information section
          _buildSectionHeader('Personal Information'),
          _buildInfoRow(Icons.person_outline_rounded, 'Full Name', widget.user.fullName),
          _buildInfoRow(Icons.email_outlined, 'Email Address', widget.user.email),
          _buildInfoRow(Icons.phone_outlined, 'Phone Number', widget.user.phone.isEmpty ? 'Not set' : widget.user.phone),
          const SizedBox(height: 24),

          // Settings section
          _buildSectionHeader('Language & Preferences'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.language_rounded, color: AppTheme.primaryColor, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Language Settings',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.neutralDark),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      _isEnglish ? 'English' : 'Français',
                      style: const TextStyle(fontSize: 12, color: AppTheme.neutralMedium),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _isEnglish,
                      onChanged: (val) {
                        setState(() {
                          _isEnglish = val;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val ? 'Language set to English' : 'Langue réglée en Français'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      activeThumbColor: AppTheme.primaryColor,

                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security Settings Section
          _buildSectionHeader('Security Settings'),
          _buildClickableRow(Icons.lock_outline_rounded, 'Change Password', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password reset email will be sent.')),
            );
          }),
          _buildClickableRow(Icons.security_rounded, 'Biometric PIN Login', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometrics verification setup initiated.')),
            );
          }),
          const SizedBox(height: 32),

          // Logout Button
          ElevatedButton.icon(
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
            label: const Text('LOG OUT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.neutralMedium,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.neutralLight)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.neutralDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClickableRow(IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.primaryColor, size: 20),
        title: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.neutralDark),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.neutralLight),
      ),
    );
  }
}
