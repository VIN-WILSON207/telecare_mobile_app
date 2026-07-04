import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

// Riverpod's AutoDisposeAsyncNotifier provides `ref` and `state`.

import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/auth_state.dart';
import '../data/models/verification_request_model.dart';
import 'verification_providers.dart';

/// Tracks the upload progress of the verification documents (0.0 to 1.0).
final submitVerificationProgressProvider =
    Provider.autoDispose<ValueNotifier<double>>((ref) {
      final notifier = ValueNotifier<double>(0.0);
      ref.onDispose(() => notifier.dispose());
      return notifier;
    });

/// Manages the state of the verification submission workflow.
class SubmitVerificationNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // No initial work needed; state is driven by [submit].
    return null;
  }

  /// Validates, uploads documents to Cloudinary, and saves the request to Firestore.
  ///
  /// [nationalIdPath] and [licensePath] must be absolute file paths on device.
  Future<void> submit({
    required String nationalIdPath,
    required String licensePath,
    required String specialty,
    required String licenseNumber,
    required String hospital,
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
    ref.read(submitVerificationProgressProvider).value = 0.0;

    try {
      final cloudinary = ref.read(cloudinaryServiceProvider);
      final repository = ref.read(verificationRepositoryProvider);

      double idProgress = 0.0;
      double licenseProgress = 0.0;

      void updateOverallProgress() {
        ref.read(submitVerificationProgressProvider).value =
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
        specialty: specialty,
        licenseNumber: licenseNumber,
        hospital: hospital,
      );

      // 4. Save request in Firestore
      await repository
          .submitVerification(request)
          .timeout(const Duration(seconds: 25));

      state = const AsyncValue.data(null);
    } on TimeoutException catch (e, st) {
      state = AsyncValue.error(
        Exception(
          'Submission is taking too long. Please check your connection and try again.',
        ),
        st,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for the SubmitVerificationNotifier.
final submitVerificationProvider =
    AsyncNotifierProvider.autoDispose<SubmitVerificationNotifier, void>(
      SubmitVerificationNotifier.new,
    );
