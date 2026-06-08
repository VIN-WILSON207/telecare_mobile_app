import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/auth_state.dart';
import 'verification_providers.dart';

/// Manages the state of the verification review actions (approve/reject).
class ReviewVerificationNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  /// Approves a doctor's verification request.
  Future<void> approve({
    required String requestId,
    required String doctorId,
  }) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) {
      state = AsyncValue.error(
        Exception('Admin must be authenticated to review requests.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();
    try {
      final repository = ref.read(verificationRepositoryProvider);
      await repository.approveVerification(
        requestId: requestId,
        doctorId: doctorId,
        reviewerId: authState.user.uid,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Rejects a doctor's verification request with a reason.
  Future<void> reject({
    required String requestId,
    required String doctorId,
    required String reason,
  }) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) {
      state = AsyncValue.error(
        Exception('Admin must be authenticated to review requests.'),
        StackTrace.current,
      );
      return;
    }

    if (reason.trim().isEmpty) {
      state = AsyncValue.error(
        Exception('Rejection reason cannot be empty.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();
    try {
      final repository = ref.read(verificationRepositoryProvider);
      await repository.rejectVerification(
        requestId: requestId,
        doctorId: doctorId,
        reviewerId: authState.user.uid,
        reason: reason.trim(),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for ReviewVerificationNotifier.
final reviewVerificationProvider =
    AutoDisposeAsyncNotifierProvider<ReviewVerificationNotifier, void>(
  ReviewVerificationNotifier.new,
);
