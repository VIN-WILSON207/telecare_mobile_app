import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telecare_mobile_app/features/auth/providers/auth_providers.dart';
import 'package:telecare_mobile_app/features/auth/providers/auth_state.dart';
import 'package:telecare_mobile_app/features/verification/providers/verification_providers.dart';
import 'package:telecare_mobile_app/features/verification/presentation/widgets/status_card.dart';

class VerificationStatusScreen extends ConsumerWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);

    // If auth is not authenticated, this shouldn't be accessible,
    // but handle gracefully.
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final doctor = authState.user;
    final verificationStream = ref.watch(currentDoctorVerificationStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome / Intro section
              Text(
                'Welcome, Dr. ${doctor.fullName}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'To maintain a secure telemedicine platform, we verify all healthcare professionals before providing access to medical features.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Verification Status Resolver
              verificationStream.when(
                data: (request) {
                  if (request == null) {
                    // Doctor has not submitted any request yet
                    return _buildUnverifiedState(context);
                  }

                  return Column(
                    children: [
                      StatusCard(
                        status: request.status,
                        date: request.submittedAt,
                        rejectionReason: request.rejectionReason,
                        onActionPressed: () => context.push('/submit-verification'),
                        actionLabel: 'Resubmit Credentials',
                      ),
                      const SizedBox(height: 24),
                      if (request.status == 'approved')
                        ElevatedButton.icon(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(Icons.dashboard_rounded),
                          label: const Text('Go to Home Dashboard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stackTrace) => Card(
                  color: theme.colorScheme.errorContainer,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: theme.colorScheme.error,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error loading status: $error',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.onErrorContainer),
                        ),
                        TextButton(
                          onPressed: () => ref.invalidate(currentDoctorVerificationStatusProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnverifiedState(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.assignment_ind_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Verification Submitted',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please submit your credentials to begin the verification process. You will need to upload your National Identity Document and your active Medical Practice License.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/submit-verification'),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Start Verification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
