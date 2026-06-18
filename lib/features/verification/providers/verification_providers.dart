import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/auth_state.dart';
import '../data/models/verification_request_model.dart';
import '../data/repositories/verification_repository.dart';
import '../services/cloudinary_service.dart';

/// Provides the singleton [CloudinaryService] instance.
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

/// Provides the [VerificationRepository] instance, injecting [firestoreProvider].
final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepository(
    firestore: ref.watch(firestoreProvider),
  );
});

/// Exposes a real-time stream of the verification request for a specific [doctorId].
final verificationStatusProvider =
    StreamProvider.family<VerificationRequestModel?, String>((ref, doctorId) {
  return ref
      .watch(verificationRepositoryProvider)
      .getVerificationStatusStream(doctorId);
});

/// Convenience provider that watches the currently authenticated user
/// and exposes their verification request stream, if they are a doctor.
final currentDoctorVerificationStatusProvider =
    StreamProvider<VerificationRequestModel?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is AuthAuthenticated) {
    return ref
        .watch(verificationRepositoryProvider)
        .getVerificationStatusStream(authState.user.uid);
  }
  return Stream.value(null);
});

/// Exposes all pending verification requests for admin view.
final pendingVerificationsProvider =
    StreamProvider<List<VerificationRequestModel>>((ref) {
  return ref.watch(verificationRepositoryProvider).getPendingRequests();
});

/// Exposes a future of a specific verification request by [requestId].
final verificationRequestByIdProvider =
    FutureProvider.family<VerificationRequestModel?, String>((ref, requestId) {
  return ref
      .watch(verificationRepositoryProvider)
      .getVerificationRequestById(requestId);
});
