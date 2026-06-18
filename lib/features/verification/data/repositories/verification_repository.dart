import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/verification_request_model.dart';

class VerificationRepository {
  final FirebaseFirestore _firestore;

  VerificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Submit Verification
  // ---------------------------------------------------------------------------

  /// Submits a new verification request.
  ///
  /// Atomically:
  /// 1. Creates a new document in `verification_requests` with auto-generated ID.
  /// 2. Updates `users/{doctorId}.verificationStatus` to `'pending'`.
  Future<void> submitVerification(VerificationRequestModel request) async {
    final batch = _firestore.batch();

    // 1. Create a new document in verification_requests
    final requestRef = _firestore.collection('verification_requests').doc();
    final requestWithId = request.copyWith(id: requestRef.id);
    batch.set(requestRef, requestWithId.toMap());

    // 2. Update the user document's verificationStatus to 'pending'
    final userRef = _firestore.collection('users').doc(request.doctorId);
    batch.update(userRef, {
      'verificationStatus': 'pending',
    });

    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Read Verification Status
  // ---------------------------------------------------------------------------

  /// Fetches the latest verification request for the given [doctorId].
  ///
  /// Returns `null` if no request has ever been submitted.
  Future<VerificationRequestModel?> getVerificationStatus(String doctorId) async {
    final snapshot = await _firestore
        .collection('verification_requests')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('submittedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return VerificationRequestModel.fromFirestore(snapshot.docs.first);
  }

  /// Exposes a real-time stream of the latest request for the given [doctorId].
  Stream<VerificationRequestModel?> getVerificationStatusStream(String doctorId) {
    return _firestore
        .collection('verification_requests')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('submittedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return VerificationRequestModel.fromFirestore(snapshot.docs.first);
    });
  }

  // ---------------------------------------------------------------------------
  // Admin Operations
  // ---------------------------------------------------------------------------

  /// Exposes a real-time stream of all requests currently in a `'pending'` status.
  Stream<List<VerificationRequestModel>> getPendingRequests() {
    return _firestore
        .collection('verification_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: false) // oldest first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VerificationRequestModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Approves a verification request.
  ///
  /// Atomically:
  /// 1. Updates `verification_requests/{requestId}.status` to `'approved'`.
  /// 2. Updates `users/{doctorId}.verificationStatus` to `'approved'`.
  /// 3. Sets approval metadata (reviewedAt, reviewedBy).
  Future<void> approveVerification({
    required String requestId,
    required String doctorId,
    required String reviewerId,
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    final requestRef = _firestore.collection('verification_requests').doc(requestId);
    batch.update(requestRef, {
      'status': 'approved',
      'reviewedAt': Timestamp.fromDate(now),
      'reviewedBy': reviewerId,
      'rejectionReason': FieldValue.delete(), // clear rejection reason if any
    });

    final userRef = _firestore.collection('users').doc(doctorId);
    batch.update(userRef, {
      'verificationStatus': 'approved',
    });

    await batch.commit();
  }

  /// Rejects a verification request with a specified reason.
  ///
  /// Atomically:
  /// 1. Updates `verification_requests/{requestId}.status` to `'rejected'`.
  /// 2. Updates `users/{doctorId}.verificationStatus` to `'rejected'`.
  /// 3. Sets rejection metadata (rejectionReason, reviewedAt, reviewedBy).
  Future<void> rejectVerification({
    required String requestId,
    required String doctorId,
    required String reviewerId,
    required String reason,
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    final requestRef = _firestore.collection('verification_requests').doc(requestId);
    batch.update(requestRef, {
      'status': 'rejected',
      'rejectionReason': reason,
      'reviewedAt': Timestamp.fromDate(now),
      'reviewedBy': reviewerId,
    });

    final userRef = _firestore.collection('users').doc(doctorId);
    batch.update(userRef, {
      'verificationStatus': 'rejected',
    });

    await batch.commit();
  }

  /// Fetches a specific verification request by [requestId].
  Future<VerificationRequestModel?> getVerificationRequestById(String requestId) async {
    final doc = await _firestore.collection('verification_requests').doc(requestId).get();
    if (!doc.exists) return null;
    return VerificationRequestModel.fromFirestore(doc);
  }
}
