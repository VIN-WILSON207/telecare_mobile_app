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
    });
  }

  /// Establishes a real-time message stream for instant sync during consultations.
  Stream<List<MessageModel>> getMessagesStream(String consultationId) {
    // Listen to changes in the subcollection using Firestore snapshots.
    return _getMessagesCollection(consultationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }
}
