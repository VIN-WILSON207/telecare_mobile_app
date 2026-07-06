import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../providers/auth_state.dart';
import '../../../../core/theme/app_theme.dart';

class PhoneOtpScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phone;

  const PhoneOtpScreen({
    super.key,
    required this.verificationId,
    required this.phone,
  });

  @override
  ConsumerState<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends ConsumerState<PhoneOtpScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  int _secondsLeft = 5 * 60; // 5 minutes
  Timer? _countdownTimer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _startCountdown();
    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _slideController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _canResend = false;
    _secondsLeft = 5 * 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _isFilled => _controllers.every((c) => c.text.isNotEmpty);

  void _onDigitInput(int index, String value) {
    // Only take the last digit if multiple chars are pasted
    final digit = value.replaceAll(RegExp(r'\D'), '');
    if (digit.isEmpty) return;

    _controllers[index].text = digit[digit.length - 1];
    _controllers[index].selection = TextSelection.fromPosition(
      TextPosition(offset: _controllers[index].text.length),
    );

    setState(() {});

    // Move to next box
    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      // Last box filled — submit automatically if all filled
      _focusNodes[index].unfocus();
      if (_isFilled) _handleVerify();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
        setState(() {});
      }
    }
  }

  // OTP verification disabled (system no longer performs OTP verification).
  // Navigation after authentication is handled using role-based verification status.
  Future<void> _handleVerify() async {
    // Intentionally no-op.
  }


  // OTP resend disabled (system no longer performs OTP verification).
  Future<void> _handleResend() async {
    // Intentionally no-op.
  }


  void _shakeBoxes() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      // OTP flow removed: we no longer react to AuthPhoneVerified/AuthOtpSent.
      // After auth, we route based on role verification status for ALL HP roles.
      if (next is AuthAuthenticated) {
        final user = next.user;
        if (user.role.requiresVerification &&
            user.verificationStatus.toLowerCase() != 'approved') {
          context.go('/verification-status');
        } else {
          context.go('/home');
        }
      } else if (next is AuthError) {

        _shakeBoxes();
        // Clear inputs on wrong verification code
        for (final c in _controllers) {
          c.clear();
        }
        setState(() {});
        _focusNodes[0].requestFocus();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
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

    return Scaffold(
      backgroundColor: AppTheme.neutralBackground,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: isLoading ? null : () => context.pop(),
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
                    const SizedBox(height: 20),
                    Text(
                      'Verify Phone',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter the 6-digit code sent to',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.phone,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── OTP Body ─────────────────────────────────────────────────────
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Phone icon in a circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primarySurface,
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.sms_outlined,
                        size: 36,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // OTP boxes
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        final dx = _shakeController.isAnimating
                            ? 12 *
                                (0.5 -
                                    (_shakeAnimation.value * 4 % 1).abs().clamp(
                                          0.0,
                                          1.0,
                                        ))
                            : 0.0;
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: child,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (i) {
                          return _OtpBox(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            index: i,
                            onInput: _onDigitInput,
                            onKeyEvent: _onKeyEvent,
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Timer
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _secondsLeft < 60
                            ? AppTheme.errorColor.withValues(alpha: 0.08)
                            : AppTheme.primarySurface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: _secondsLeft < 60
                              ? AppTheme.errorColor.withValues(alpha: 0.3)
                              : AppTheme.primaryColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: _secondsLeft < 60
                                ? AppTheme.errorColor
                                : AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _canResend
                                ? 'OTP expired'
                                : 'Expires in  $_timerText',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _secondsLeft < 60
                                  ? AppTheme.errorColor
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Resend button
                    TextButton(
                      onPressed: (!_canResend || isLoading) ? null : _handleResend,
                      child: Text(
                        _canResend ? 'Resend OTP' : 'Resend code when timer expires',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _canResend
                              ? AppTheme.primaryColor
                              : AppTheme.neutralLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Verify button
                    _VerifyButton(
                      isFilled: _isFilled,
                      isLoading: isLoading,
                      onPressed: _handleVerify,
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Didn\'t receive a code? Check your SMS inbox\nor contact support.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.neutralLight,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 20),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DEMO MODE',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.amber.shade800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your verification code is: ${widget.verificationId}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── OTP Box ────────────────────────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.index,
    required this.onInput,
    required this.onKeyEvent,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int index;
  final void Function(int, String) onInput;
  final void Function(int, KeyEvent) onKeyEvent;

  @override
  Widget build(BuildContext context) {
    final isFilled = controller.text.isNotEmpty;

    return Container(
      width: 46,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: isFilled ? AppTheme.primarySurface : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFilled
              ? AppTheme.primaryColor
              : const Color(0xFFE2E8F0),
          width: isFilled ? 2 : 1.5,
        ),
        boxShadow: isFilled
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : [],
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) => onKeyEvent(index, event),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryDark,
            fontFamily: 'Poppins',
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            filled: false,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) => onInput(index, value),
        ),
      ),
    );
  }
}

// ── Verify Button ─────────────────────────────────────────────────────────────
class _VerifyButton extends StatelessWidget {
  const _VerifyButton({
    required this.isFilled,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isFilled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: (isFilled && !isLoading)
            ? const LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primaryLight],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: (isFilled && !isLoading) ? null : AppTheme.neutralSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: (isFilled && !isLoading)
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: (isFilled && !isLoading) ? onPressed : null,
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
                'Verify & Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: isFilled ? Colors.white : AppTheme.neutralLight,
                ),
              ),
      ),
    );
  }
}
