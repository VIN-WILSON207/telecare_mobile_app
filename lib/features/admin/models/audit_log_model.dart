import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String id;
  final String action;
  final String userId;
  final String userName;
  final String details;
  final DateTime timestamp;

  const AuditLogModel({
    required this.id,
    required this.action,
    required this.userId,
    required this.userName,
    required this.details,
    required this.timestamp,
  });

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLogModel(
      id: doc.id,
      action: data['action'] as String? ?? 'unknown',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'System',
      details: data['details'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'userId': userId,
      'userName': userName,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
