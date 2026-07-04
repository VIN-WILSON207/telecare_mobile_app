import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/data/models/user_model.dart';
import '../../appointments/data/models/appointment_model.dart';
import '../../verification/data/models/verification_request_model.dart';
import '../models/audit_log_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // User Management
  // ---------------------------------------------------------------------------

  /// Exposes a real-time stream of all user documents.
  Stream<List<UserModel>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map(UserModel.fromFirestore).toList();
    });
  }

  /// Activates or deactivates a user's access to the platform.
  Future<void> setUserActiveStatus({
    required String uid,
    required bool isActive,
    required String adminId,
    required String adminName,
  }) async {
    final batch = _firestore.batch();
    
    // Update user status
    final userRef = _firestore.collection('users').doc(uid);
    batch.update(userRef, {'isActive': isActive});

    // Write audit log
    final auditRef = _firestore.collection('audit_logs').doc();
    batch.set(auditRef, {
      'id': auditRef.id,
      'action': 'profile_update',
      'userId': adminId,
      'userName': adminName,
      'details': '${isActive ? "Activated" : "Deactivated"} user $uid',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Deletes a user profile document from Firestore.
  Future<void> deleteUser({
    required String uid,
    required String adminId,
    required String adminName,
  }) async {
    final batch = _firestore.batch();

    // Delete user doc
    final userRef = _firestore.collection('users').doc(uid);
    batch.delete(userRef);

    // Write audit log
    final auditRef = _firestore.collection('audit_logs').doc();
    batch.set(auditRef, {
      'id': auditRef.id,
      'action': 'profile_update',
      'userId': adminId,
      'userName': adminName,
      'details': 'Deleted user document $uid',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Appointment Management
  // ---------------------------------------------------------------------------

  /// Exposes a real-time stream of all appointments.
  Stream<List<AppointmentModel>> getAppointmentsStream() {
    return _firestore
        .collection('appointments')
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Verification Requests
  // ---------------------------------------------------------------------------

  /// Exposes a real-time stream of all verification requests.
  Stream<List<VerificationRequestModel>> getAllVerificationRequestsStream() {
    return _firestore
        .collection('verification_requests')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(VerificationRequestModel.fromFirestore)
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Audit Logs
  // ---------------------------------------------------------------------------

  /// Exposes a real-time stream of audit logs.
  Stream<List<AuditLogModel>> getAuditLogsStream() {
    return _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(AuditLogModel.fromFirestore).toList();
    });
  }

  /// Logs a custom action to the audit logs collection.
  Future<void> logAction({
    required String action,
    required String details,
    required String adminId,
    required String adminName,
  }) async {
    final auditRef = _firestore.collection('audit_logs').doc();
    await auditRef.set({
      'id': auditRef.id,
      'action': action,
      'userId': adminId,
      'userName': adminName,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
