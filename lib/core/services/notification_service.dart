import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed in-app notification service.
///
/// This intentionally does not use Firebase Cloud Messaging. Open app sessions
/// receive updates through Firestore snapshot listeners on `notifications`.
class NotificationService {
  NotificationService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserNotifications(
    String userId,
  ) {
    return _firestore
        .collection('notifications')
        .where('targetUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String notificationId) {
    return _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    final notificationRef = _firestore.collection('notifications').doc();
    await notificationRef.set({
      'id': notificationRef.id,
      'targetUserId': targetUserId,
      'title': title,
      'body': body,
      'type': data['type'] ?? 'general',
      'data': data,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static String? resolveRoute(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'appointment_request':
      case 'appointment_approved':
        return '/appointments';
      case 'consultation_started':
        return '/consultations';
      default:
        return null;
    }
  }

  static Map<String, dynamic> buildAppointmentRequestPayload({
    required String patientName,
    required String appointmentDate,
  }) {
    return {
      'title': 'New Appointment Request',
      'body': '$patientName has requested an appointment on $appointmentDate.',
      'data': {'type': 'appointment_request'},
    };
  }

  static Map<String, dynamic> buildAppointmentApprovedPayload({
    required String doctorName,
    required String appointmentDate,
  }) {
    return {
      'title': 'Appointment Approved',
      'body':
          'Dr. $doctorName has approved your appointment on $appointmentDate.',
      'data': {'type': 'appointment_approved'},
    };
  }

  static Map<String, dynamic> buildConsultationStartedPayload({
    required String doctorName,
    required String consultationId,
    required String roomId,
  }) {
    return {
      'title': 'Your Doctor is Ready',
      'body': 'Dr. $doctorName is ready to begin your consultation.',
      'data': {
        'type': 'consultation_started',
        'consultationId': consultationId,
        'roomId': roomId,
      },
    };
  }
}
