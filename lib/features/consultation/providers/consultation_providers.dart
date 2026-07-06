import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/service_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/models/consultation_model.dart';
import '../data/models/message_model.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/consultation_repository.dart';
import '../data/services/consultation_service.dart';

final consultationRepositoryProvider = Provider<ConsultationRepository>((ref) {
  return ConsultationRepository(firestore: ref.watch(firestoreProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(firestore: ref.watch(firestoreProvider));
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

final chatRoomMessagesProvider = StreamProvider.autoDispose
    .family<List<MessageModel>, ChatRoomMessagesQuery>((ref, query) {
  return ref.watch(chatRepositoryProvider).watchRoomMessages(
        roomId: query.roomId,
        viewerId: query.viewerId,
      );
});

class ChatRoomMessagesQuery {
  final String roomId;
  final String viewerId;

  const ChatRoomMessagesQuery({
    required this.roomId,
    required this.viewerId,
  });

  @override
  bool operator ==(Object other) {
    return other is ChatRoomMessagesQuery &&
        other.roomId == roomId &&
        other.viewerId == viewerId;
  }

  @override
  int get hashCode => Object.hash(roomId, viewerId);
}
