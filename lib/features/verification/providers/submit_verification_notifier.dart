import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/auth_state.dart';
import '../data/models/verification_request_model.dart';
import 'verification_providers.dart';

/// Tracks the upload progress of the verification documents (0.0 to 1.0).
final submitVerificationProgressProvider = StateProvider.autoDispose<double>((ref) => 0.0);

/// Manages the state of the verification submission workflow.
///
/// State transitions:
/// - Initial: [AsyncValue.data(null)] (idle)
/// - Submitting: [AsyncValue.loading()]
/// - Success: [AsyncValue.data(null)] (indicates completed submission)
/// - Failure: [AsyncValue.error(error, stackTrace)]
class SubmitVerificationNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Return nothing initially (idle state)
    return null;
  }

  /// Validates, uploads documents to Cloudinary, and saves the request to Firestore.
  ///
  /// [nationalIdPath] and [licensePath] must be absolute file paths on device.
  Future<void> submit({
    required String nationalIdPath,
    required String licensePath,
  }) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) {
      state = AsyncValue.error(
        Exception('User must be authenticated to submit verification.'),
        StackTrace.current,
      );
      return;
    }

    final doctor = authState.user;
    state = const AsyncValue.loading();
    ref.read(submitVerificationProgressProvider.notifier).state = 0.0;

    try {
      final cloudinary = ref.read(cloudinaryServiceProvider);
      final repository = ref.read(verificationRepositoryProvider);

      double idProgress = 0.0;
      double licenseProgress = 0.0;

      void updateOverallProgress() {
        ref.read(submitVerificationProgressProvider.notifier).state =
            (idProgress + licenseProgress) / 2.0;
      }

      // 1. Upload National ID
      final nationalIdUrl = await cloudinary.uploadNationalId(
        nationalIdPath,
        onProgress: (p) {
          idProgress = p;
          updateOverallProgress();
        },
      );

      // 2. Upload Medical License
      final licenseUrl = await cloudinary.uploadLicense(
        licensePath,
        onProgress: (p) {
          licenseProgress = p;
          updateOverallProgress();
        },
      );

      // 3. Create the verification request model
      final request = VerificationRequestModel(
        id: '', // Will be set by repository batch/doc ID
        doctorId: doctor.uid,
        doctorName: doctor.fullName,
        nationalIdUrl: nationalIdUrl,
        licenseUrl: licenseUrl,
        status: 'pending',
        submittedAt: DateTime.now(),
      );

      // 4. Save request in Firestore
      await repository.submitVerification(request);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for the SubmitVerificationNotifier.
final submitVerificationProvider =
    AutoDisposeAsyncNotifierProvider<SubmitVerificationNotifier, void>(
  SubmitVerificationNotifier.new,
);
