import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../auth/providers/auth_state.dart';
import '../../providers/verification_providers.dart';
import '../widgets/status_card.dart';

class VerificationStatusScreen extends ConsumerWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final size = MediaQuery.of(context).size;

    // If auth is not authenticated, show loading.
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        backgroundColor: AppTheme.neutralBackground,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final doctor = authState.user;
    final verificationStream = ref.watch(currentDoctorVerificationStatusProvider);

    return Scaffold(
      backgroundColor: AppTheme.neutralBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Curved Green Header ──────────────────────────────────────
            Container(
              width: double.infinity,
              height: size.height * 0.32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryDark,
                    AppTheme.primaryColor,
                    AppTheme.primaryLight,
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // Decorative circle
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    // Logout button in the top right
                    Positioned(
                      top: 12,
                      right: 20,
                      child: GestureDetector(
                        onTap: () {
                          ref.read(authNotifierProvider.notifier).logout();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),
                            // Doctor Badge Icon
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.badge_outlined,
                                size: 36,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Dr. ${doctor.fullName}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Doctor Verification Portal',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Main Content / Status Card ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Transform.translate(
                offset: const Offset(0, -28),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Verification Status',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'To ensure the highest safety and security standards, we verify all healthcare providers before unlocking medical consultations.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.neutralMedium),
                      ),
                      const SizedBox(height: 24),

                      // Status View
                      verificationStream.when(
                        data: (request) {
                          if (request == null) {
                            return _buildUnverifiedState(context);
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              StatusCard(
                                status: request.status,
                                date: request.submittedAt,
                                rejectionReason: request.rejectionReason,
                                onActionPressed: () =>
                                    context.push('/submit-verification'),
                                actionLabel: 'Resubmit Credentials',
                              ),
                              if (request.status == 'approved') ...[
                                const SizedBox(height: 24),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor,
                                        AppTheme.primaryLight
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMedium),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.3),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () => context.go('/home'),
                                    icon: const Icon(Icons.dashboard_rounded,
                                        color: Colors.white),
                                    label: const Text('Go to Home Dashboard'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      minimumSize: const Size(double.infinity, 54),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusMedium),
                                      ),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, stackTrace) => Column(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppTheme.errorColor,
                              size: 44,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Error loading status:\n$error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppTheme.neutralDark,
                                  fontFamily: 'Poppins',
                                  fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => ref.invalidate(
                                  currentDoctorVerificationStatusProvider),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
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
      ),
    );
  }

  Widget _buildUnverifiedState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Icon(
            Icons.assignment_ind_outlined,
            size: 72,
            color: AppTheme.neutralLight,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No Verification Submitted',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
            color: AppTheme.neutralDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please submit your credentials to begin the verification process. You will need to upload your National Identity Document and your active Medical Practice License.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.neutralMedium,
            fontFamily: 'Poppins',
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryLight],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => context.push('/submit-verification'),
            icon: const Icon(Icons.send_rounded, color: Colors.white),
            label: const Text('Start Verification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
