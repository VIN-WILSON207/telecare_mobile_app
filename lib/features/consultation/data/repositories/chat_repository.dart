import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

/// Repository for handling real-time chat operations between patients and doctors.
class ChatRepository {
  final FirebaseFirestore _firestore;

  /// Creates a [ChatRepository] with a Firestore instance.
  ChatRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Retrieves a reference to the messages subcollection for a given consultation.
  CollectionReference _getMessagesCollection(String consultationId) {
    return _firestore
        .collection('consultations')
        .doc(consultationId)
        .collection('messages');
  }

  CollectionReference<Map<String, dynamic>> get _chatRooms =>
      _firestore.collection('chat_rooms');

  String roomIdForPair({required String doctorId, required String patientId}) {
    return 'doctor_${doctorId}_patient_$patientId';
  }

  Future<String> getOrCreateRoom({
    required String doctorId,
    required String patientId,
    required String appointmentId,
    required String consultationId,
  }) async {
    final roomId = roomIdForPair(doctorId: doctorId, patientId: patientId);
    final roomRef = _chatRooms.doc(roomId);

    final existing = await roomRef.get();
    if (existing.exists) {
      await roomRef.update({'updatedAt': FieldValue.serverTimestamp()});
    } else {
      await roomRef.set({
        'id': roomId,
        'doctorId': doctorId,
        'patientId': patientId,
        'participants': [doctorId, patientId],
        'appointmentId': appointmentId,
        'consultationId': consultationId,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return roomId;
  }

  CollectionReference<Map<String, dynamic>> _roomMessages(String roomId) {
    return _chatRooms.doc(roomId).collection('messages');
  }

  /// Sends a message programmatically to the consultation chat thread.
  Future<void> sendMessage({
    required String consultationId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    // Add the message document to the subcollection with a server timestamp.
    await _getMessagesCollection(consultationId).add({
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'status': 'sent',
    });
  }

  Future<void> sendRoomMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    String text = '',
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    if (text.trim().isEmpty &&
        (attachmentUrl == null || attachmentUrl.isEmpty)) {
      return;
    }

    final batch = _firestore.batch();
    final messageRef = _roomMessages(roomId).doc();
    batch.set(messageRef, {
      'id': messageRef.id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text.trim(),
      if (attachmentUrl != null && attachmentUrl.isNotEmpty)
        'attachmentUrl': attachmentUrl,
      if (attachmentType != null && attachmentType.isNotEmpty)
        'attachmentType': attachmentType,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      'isRead': false,
      'deletedFor': <String>[],
    });
    batch.update(_chatRooms.doc(roomId), {
      'lastMessage': text.trim().isEmpty ? 'Attachment' : text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Establishes a real-time message stream for instant sync during consultations.
  Stream<List<MessageModel>> getMessagesStream(String consultationId) {
    // Listen to changes in the subcollection using Firestore snapshots.
    return _getMessagesCollection(consultationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<MessageModel>> watchRoomMessages({
    required String roomId,
    required String viewerId,
  }) {
    return _roomMessages(roomId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .where((message) => !message.deletedFor.contains(viewerId))
              .toList(),
        );
  }

  Future<void> markMessageRead({
    required String roomId,
    required String messageId,
  }) {
    return _roomMessages(roomId).doc(messageId).update({
      'isRead': true,
      'status': 'read',
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteForSender({
    required String roomId,
    required String messageId,
    required String senderId,
  }) {
    return _roomMessages(roomId).doc(messageId).update({
      'deletedFor': FieldValue.arrayUnion([senderId]),
    });
  }

  /// Streams all chat rooms where the current user is a participant, ordered by updatedAt.
  Stream<List<Map<String, dynamic>>> watchUserChatRooms(String userId) {
    return _chatRooms
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
