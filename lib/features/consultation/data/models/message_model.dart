import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a single chat message inside a consultation session.
class MessageModel {
  /// The unique document ID of the message.
  final String id;

  /// The unique ID of the sender (either patient or doctor).
  final String senderId;

  /// The name of the sender.
  final String senderName;

  /// The message text content.
  final String text;

  /// Optional Cloudinary secure URL for image/PDF/document attachments.
  final String? attachmentUrl;

  /// Attachment MIME/category hint, for example image, pdf, or document.
  final String? attachmentType;

  /// The timestamp of when the message was sent.
  final DateTime timestamp;

  /// Flag indicating whether the message has been read.
  final bool isRead;

  /// Delivery/read status used by chat-room messages.
  final String status;

  /// User IDs for whom this message is hidden.
  final List<String> deletedFor;

  /// Creates a [MessageModel] instance.
  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.attachmentUrl,
    this.attachmentType,
    required this.timestamp,
    this.isRead = false,
    this.status = 'sent',
    this.deletedFor = const [],
  });

  /// Converts this [MessageModel] into a Firestore-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (attachmentType != null) 'attachmentType': attachmentType,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'status': status,
      'deletedFor': deletedFor,
    };
  }

  /// Creates a [MessageModel] from a Firestore document snapshot.
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      text: data['text'] as String? ?? '',
      attachmentUrl: data['attachmentUrl'] as String?,
      attachmentType: data['attachmentType'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      status:
          data['status'] as String? ??
          (data['isRead'] == true ? 'read' : 'sent'),
      deletedFor: List<String>.from(data['deletedFor'] as List? ?? const []),
    );
  }
}
