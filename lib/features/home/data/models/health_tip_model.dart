import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a health tip posted by verified personnel or admins.
class HealthTipModel {
  /// The unique document ID of the health tip.
  final String id;

  /// The title of the health tip.
  final String title;

  /// The detailed text content of the health tip.
  final String content;

  /// The name of the author who wrote the tip.
  final String authorName;

  /// The unique user ID of the author.
  final String authorId;

  /// The role of the author (e.g. 'doctor' or 'admin').
  final String authorRole;

  /// The timestamp of when the tip was posted.
  final DateTime createdAt;

  /// Creates a [HealthTipModel] instance.
  const HealthTipModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.authorId,
    required this.authorRole,
    required this.createdAt,
  });

  /// Converts this [HealthTipModel] into a Firestore Map.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'authorName': authorName,
      'authorId': authorId,
      'authorRole': authorRole,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a [HealthTipModel] from a Firestore document snapshot.
  factory HealthTipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HealthTipModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorRole: data['authorRole'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
