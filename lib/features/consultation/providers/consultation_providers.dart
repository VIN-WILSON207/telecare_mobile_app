import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/service_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/models/consultation_model.dart';
import '../data/repositories/consultation_repository.dart';
import '../data/services/consultation_service.dart';

final consultationRepositoryProvider = Provider<ConsultationRepository>((ref) {
  return ConsultationRepository(firestore: ref.watch(firestoreProvider));
});

/// Provides the [ConsultationService] with all required dependencies.
final consultationServiceProvider = Provider<ConsultationService>((ref) {
  return ConsultationService(
    repository: ref.watch(consultationRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});

/// Stream a single consultation by consultationId.
final consultationStreamProvider = StreamProvider.autoDispose
    .family<ConsultationModel?, String>((ref, consultationId) {
  return ref
      .watch(consultationRepositoryProvider)
      .watchConsultation(consultationId);
});

/// Stream all consultations for the current user (by uid).
final userConsultationsProvider = StreamProvider.autoDispose
    .family<List<ConsultationModel>, String>((ref, uid) {
  return ref
      .watch(consultationRepositoryProvider)
      .watchUserConsultations(uid);
});
