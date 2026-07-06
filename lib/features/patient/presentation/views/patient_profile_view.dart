import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../core/widgets/telecare_ui.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../verification/services/cloudinary_service.dart';

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
  bool _useBiometric = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
  }

  void _loadBiometricSettings() {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _useBiometric = prefs.getBool('use_biometric') ?? false;
    });
  }

  Future<String?> _promptForPassword() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Password', style: TextStyle(color: AppTheme.neutralDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please enter your password to enable biometric login.',
              style: TextStyle(fontSize: 13, color: AppTheme.neutralMedium),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              style: TeleCareInputStyles.formTextStyle,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _setupBiometricLogin() async {
    final messenger = ScaffoldMessenger.of(context);
    final auth = LocalAuthentication();
    final prefs = ref.read(sharedPreferencesProvider);

    if (_useBiometric) {
      // Toggle off
      await prefs.setBool('use_biometric', false);
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'saved_email');
      await storage.delete(key: 'saved_password');
      setState(() {
        _useBiometric = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Biometric login disabled.')),
      );
      return;
    }

    try {
      final isSupported = await auth.isDeviceSupported();
      final canCheck = await auth.canCheckBiometrics;
      if (!isSupported || !canCheck) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication is not available on this device.'),
          ),
        );
        return;
      }

      final authenticated = await auth.authenticate(
        localizedReason: 'Verify your identity to enable biometric login.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!authenticated) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Biometric verification was cancelled.')),
        );
        return;
      }

      final password = await _promptForPassword();
      if (password == null || password.isEmpty) return;

      // Show loader
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );

      // Verify the password by reauthenticating
      try {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.signInWithEmailAndPassword(
          email: widget.user.email,
          password: password,
        );
        
        // Save credentials securely
        const storage = FlutterSecureStorage();
        await storage.write(key: 'saved_email', value: widget.user.email);
        await storage.write(key: 'saved_password', value: password);
        await prefs.setBool('use_biometric', true);

        if (mounted) Navigator.of(context).pop(); // pop loader

        setState(() {
          _useBiometric = true;
        });

        messenger.showSnackBar(
          const SnackBar(content: Text('Biometric login successfully enabled.')),
        );
      } catch (authError) {
        if (mounted) Navigator.of(context).pop(); // pop loader
        messenger.showSnackBar(
          const SnackBar(content: Text('Verification failed: Incorrect password.')),
        );
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Biometric verification failed: $error')),
      );
    }
  }

  Future<void> _changeProfilePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile == null) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );

    try {
      final cloudinary = CloudinaryService();
      final url = await cloudinary.uploadFile(pickedFile.path, folder: 'profile_photos');

      final firestore = ref.read(firestoreProvider);
      await firestore.collection('users').doc(widget.user.uid).update({
        'profileImage': url,
      });

      final updatedProfile = await ref.read(authRepositoryProvider).getUserProfile(widget.user.uid);
      if (updatedProfile != null) {
        ref.read(authNotifierProvider.notifier).updateAuthenticatedUser(updatedProfile);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e')),
        );
      }
    }
  }

  Future<void> _editPhoneNumber() async {
    final controller = TextEditingController(text: widget.user.phone);
    final lang = ref.watch(languageProvider);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('edit_phone', lang)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: tr('phone_number', lang),
            prefixIcon: const Icon(Icons.phone_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );

    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('users').doc(widget.user.uid).update({
        'phone': result,
      });

      final updatedProfile = await ref.read(authRepositoryProvider).getUserProfile(widget.user.uid);
      if (updatedProfile != null) {
        ref.read(authNotifierProvider.notifier).updateAuthenticatedUser(updatedProfile);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update phone number: $e')),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final lang = ref.watch(languageProvider);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('change_password', lang)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (newController.text != confirmController.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match.')),
                );
                return;
              }
              if (newController.text.length < 6) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters.')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (result != true) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: currentController.text,
        );
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(newController.text);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update password: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isEnglish = lang == 'en';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _changeProfilePhoto,
                  child: Stack(
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
                    tr('patient_account', lang),
                    style: const TextStyle(
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
          _buildSectionHeader(tr('personal_info', lang)),
          _buildInfoRow(Icons.person_outline_rounded, tr('full_name', lang), widget.user.fullName),
          _buildInfoRow(Icons.email_outlined, tr('email_address', lang), widget.user.email),
          _buildInfoRow(
            Icons.phone_outlined,
            tr('phone_number', lang),
            widget.user.phone.isEmpty ? 'Not set' : widget.user.phone,
            onTap: _editPhoneNumber,
          ),
          const SizedBox(height: 24),

          // Settings section
          _buildSectionHeader(tr('lang_pref', lang)),
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
                  children: [
                    const Icon(Icons.language_rounded, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      tr('lang_settings', lang),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.neutralDark),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      isEnglish ? 'English' : 'Français',
                      style: const TextStyle(fontSize: 12, color: AppTheme.neutralMedium),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: isEnglish,
                      onChanged: (val) {
                        ref.read(languageProvider.notifier).setLanguage(val ? 'en' : 'fr');
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
          _buildSectionHeader(tr('security_settings', lang)),
          _buildClickableRow(Icons.lock_outline_rounded, tr('change_password', lang), _changePassword),
          _buildClickableRow(
            Icons.security_rounded,
            tr('biometric_login', lang),
            _setupBiometricLogin,
            trailing: Text(
              _useBiometric ? 'Enabled' : 'Disabled',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _useBiometric ? AppTheme.primaryColor : AppTheme.neutralMedium,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          ElevatedButton.icon(
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
            label: Text(tr('log_out', lang)),
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

  Widget _buildInfoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.neutralLight)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.neutralDark)),
          ],
        ),
        trailing: onTap != null ? const Icon(Icons.edit_rounded, size: 16, color: AppTheme.primaryColor) : null,
      ),
    );
  }

  Widget _buildClickableRow(IconData icon, String label, VoidCallback onTap, {Widget? trailing}) {
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
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.neutralLight),
      ),
    );
  }
}
