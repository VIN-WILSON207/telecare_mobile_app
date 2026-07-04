import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_role.dart';
import '../../providers/auth_providers.dart';
import '../../providers/auth_state.dart';
import '../../../../core/theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  // Step 1: Role
  UserRole _selectedRole = UserRole.patient;

  // Step 2: Personal Info + Security
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '+237 ');
  final _dateOfBirthController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _selectedGender;

  // Step 2: Security
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  int _currentStep = 0;
  static const int _totalSteps = 2;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  int get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    if (p.length < 6) return 1;
    if (p.length < 10) return 2;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'\d').hasMatch(p)) return 4;
    return 3;
  }

  Color get _strengthColor {
    switch (_passwordStrength) {
      case 1:
        return AppTheme.errorColor;
      case 2:
        return AppTheme.warningColor;
      case 3:
        return AppTheme.infoColor;
      case 4:
        return AppTheme.successColor;
      default:
        return AppTheme.neutralLight;
    }
  }

  String get _strengthLabel {
    switch (_passwordStrength) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (!_formKeys[_currentStep].currentState!.validate()) return;
    if (_currentStep < _totalSteps - 1) {
      _slideController.reset();
      setState(() => _currentStep++);
      _slideController.forward();
    } else {
      _handleRegister();
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      _slideController.reset();
      setState(() => _currentStep--);
      _slideController.forward();
    } else {
      context.pop();
    }
  }

  Future<void> _handleRegister() async {
    await ref
        .read(authNotifierProvider.notifier)
        .register(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
          role: _selectedRole,
          dateOfBirth: _dateOfBirth!,
          gender: _selectedGender!,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthRegistrationSuccess) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppTheme.successColor,
              size: 48,
            ),
            title: const Text(
              'Registration Successful',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Your TeleCare account has been created successfully. Please sign in to access your dashboard.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
                child: const Text('Sign In Now'),
              ),
            ],
          ),
        );
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(next.message)),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
      }
    });

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 0) {
          _goBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.neutralBackground,
        body: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button + step indicator
                      Row(
                        children: [
                          GestureDetector(
                            onTap: isLoading ? null : _goBack,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Step pill progress
                          Row(
                            children: List.generate(_totalSteps, (i) {
                              final isActive = i == _currentStep;
                              final isDone = i < _currentStep;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(left: 6),
                                width: isActive ? 28 : 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: (isActive || isDone)
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Create Account',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Step ${_currentStep + 1} of $_totalSteps · ${_stepTitle(_currentStep)}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Step Content ─────────────────────────────────────────────
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildStep(_currentStep, isLoading),
                  ),
                ),
              ),
            ),

            // ── Bottom Button ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: _GradientButton(
                label: _currentStep < _totalSteps - 1
                    ? 'Next  →'
                    : 'Create Account',
                isLoading: isLoading && _currentStep == _totalSteps - 1,
                onPressed: isLoading ? () {} : _goNext,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 0:
        return 'Choose Role';
      case 1:
        return 'Personal Information';
      default:
        return '';
    }
  }

  Widget _buildStep(int step, bool isLoading) {
    switch (step) {
      case 0:
        return _buildRoleStep(isLoading);
      case 1:
        return _buildPersonalInfoStep(isLoading);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: Personal Info ─────────────────────────────────────────────────
  Widget _buildPersonalInfoStep(bool isLoading) {
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(label: 'Full Name', icon: Icons.person_outline),
          const SizedBox(height: 8),
          TextFormField(
            controller: _fullNameController,
            enabled: !isLoading,
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins',
              fontSize: 18,
            ),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. Vin-Wilson Anu',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Full name is required';
              if (v.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          _SectionLabel(label: 'Email Address', icon: Icons.email_outlined),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins',
              fontSize: 18,
            ),
            decoration: const InputDecoration(
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          _SectionLabel(label: 'Phone Number', icon: Icons.phone_outlined),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            enabled: !isLoading,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins',
              fontSize: 18,
            ),
            decoration: const InputDecoration(
              hintText: '+237 600 000 000',
              prefixIcon: Icon(Icons.phone_outlined),
              helperText: 'Include country code (e.g. +237 for Cameroon)',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Phone number is required';
              }
              if (v.trim().length < 8) return 'Enter a valid phone number';
              return null;
            },
          ),
          const SizedBox(height: 18),

          _SectionLabel(label: 'Date of Birth', icon: Icons.cake_outlined),
          const SizedBox(height: 8),
          TextFormField(
            controller: _dateOfBirthController,
            enabled: !isLoading,
            readOnly: true,
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins',
              fontSize: 18,
            ),
            decoration: const InputDecoration(
              hintText: 'Select your date of birth',
              prefixIcon: Icon(Icons.cake_outlined),
              suffixIcon: Icon(Icons.calendar_month_outlined),
              helperText: 'Patients must be 18+, healthcare professionals 23+.',
            ),
            onTap: isLoading ? null : _pickDateOfBirth,
            validator: (_) {
              if (_dateOfBirth == null) return 'Date of birth is required';
              final minAge = _minimumAgeForRole;
              final age = _ageFromDob(_dateOfBirth!);
              if (age < minAge) {
                return _selectedRole == UserRole.doctor
                    ? 'Healthcare professionals must be at least 23 years old'
                    : 'Patients must be at least 18 years old';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          _SectionLabel(label: 'Gender', icon: Icons.wc_outlined),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedGender,
            dropdownColor: AppTheme.primarySurface,
            items: const [
              DropdownMenuItem(value: 'female', child: Text('Female')),
              DropdownMenuItem(value: 'male', child: Text('Male')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
              DropdownMenuItem(
                value: 'prefer_not_to_say',
                child: Text('Prefer not to say'),
              ),
            ],
            onChanged: isLoading
                ? null
                : (value) => setState(() => _selectedGender = value),
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins',
              fontSize: 18,
            ),
            decoration: InputDecoration(
              hintText: 'Select gender',
              prefixIcon: const Icon(Icons.wc_outlined),
              fillColor: AppTheme.primarySurface,
            ),
            validator: (v) => v == null ? 'Gender is required' : null,
          ),
          const SizedBox(height: 18),

          _SectionLabel(label: 'Create Password', icon: Icons.lock_outline),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !isLoading,
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins',
              fontSize: 18,
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Min. 6 characters',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.neutralLight,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Minimum 6 characters required';
              return null;
            },
          ),
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 4),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < _passwordStrength
                          ? _strengthColor
                          : AppTheme.neutralSurface,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Password strength:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.neutralMedium,
                  ),
                ),
                Text(
                  _strengthLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _strengthColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),

          _SectionLabel(label: 'Confirm Password', icon: Icons.lock_outline),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            enabled: !isLoading,
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins',
              fontSize: 18,
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Repeat your password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: _confirmPasswordController.text.isNotEmpty
                  ? Icon(
                      _confirmPasswordController.text ==
                              _passwordController.text
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      color: _confirmPasswordController.text ==
                              _passwordController.text
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    )
                  : IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.neutralLight,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: const Text(
              'We use DOB and gender to personalize health preferences, reminders, and care recommendations.',
              style: TextStyle(
                color: AppTheme.neutralDark,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final minAge = _minimumAgeForRole;
    final latestAllowedDob = DateTime(now.year - minAge, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? latestAllowedDob,
      firstDate: DateTime(now.year - 120),
      lastDate: latestAllowedDob,
    );
    if (picked == null) return;
    setState(() {
      _dateOfBirth = picked;
      _dateOfBirthController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    });
  }

  int get _minimumAgeForRole => _selectedRole == UserRole.doctor ? 23 : 18;

  int _ageFromDob(DateTime dob) {
    final today = DateTime.now();
    var age = today.year - dob.year;
    final birthdayThisYear = DateTime(today.year, dob.month, dob.day);
    if (today.isBefore(birthdayThisYear)) age--;
    return age;
  }

  // ── Step 2: Password ──────────────────────────────────────────────────────
  // ignore: unused_element
  Widget _buildPasswordStep(bool isLoading) {
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(label: 'Create Password', icon: Icons.lock_outline),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !isLoading,
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins',
              fontSize: 17,
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Min. 6 characters',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.neutralLight,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Minimum 6 characters required';
              return null;
            },
          ),

          // Password strength bar
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 4),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < _passwordStrength
                          ? _strengthColor
                          : AppTheme.neutralSurface,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Password strength:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.neutralMedium,
                  ),
                ),
                Text(
                  _strengthLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _strengthColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),

          _SectionLabel(label: 'Confirm Password', icon: Icons.lock_outline),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            enabled: !isLoading,
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins',
              fontSize: 17,
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Repeat your password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: _confirmPasswordController.text.isNotEmpty
                  ? Icon(
                      _confirmPasswordController.text ==
                              _passwordController.text
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      color:
                          _confirmPasswordController.text ==
                              _passwordController.text
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    )
                  : IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.neutralLight,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Terms note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'By registering, you agree to our Terms of Service and Privacy Policy.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Role Selection ────────────────────────────────────────────────
  Widget _buildRoleStep(bool isLoading) {
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'I am a...',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutralMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          _RoleCard(
            icon: Icons.person_rounded,
            title: 'Patient',
            subtitle: 'Book consultations & manage my health',
            isSelected: _selectedRole == UserRole.patient,
            enabled: !isLoading,
            onTap: () => setState(() => _selectedRole = UserRole.patient),
          ),
          const SizedBox(height: 14),

          _RoleCard(
            icon: Icons.medical_services_rounded,
            title: 'Healthcare Professional',
            subtitle: 'Provide verified remote consultations',
            isSelected: _selectedRole == UserRole.doctor,
            enabled: !isLoading,
            onTap: () => setState(() => _selectedRole = UserRole.doctor),
          ),

          if (_selectedRole == UserRole.doctor) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.warningColor.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Healthcare professionals must upload their Medical License and Government ID for verification before accessing the platform.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.statusPendingText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Role Card ─────────────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.06)
              : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTheme.cardShadow : [],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.15)
                    : AppTheme.neutralSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 26,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.neutralLight,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? AppTheme.primaryDark
                          : AppTheme.neutralDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.neutralMedium,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primaryColor,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppTheme.neutralDark,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── Gradient Button ───────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 58,
      decoration: BoxDecoration(
        gradient: isLoading
            ? null
            : const LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primaryLight],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: isLoading ? AppTheme.neutralLight : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isLoading
            ? []
            : [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
