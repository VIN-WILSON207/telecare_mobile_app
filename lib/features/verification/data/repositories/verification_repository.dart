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
    batch.set(userRef, {
      'verificationStatus': 'pending',
    }, SetOptions(merge: true));

    await batch.commit().timeout(const Duration(seconds: 25));
  }

  // ---------------------------------------------------------------------------
  // Read Verification Status
  // ---------------------------------------------------------------------------

  /// Fetches the latest verification request for the given [doctorId].
  ///
  /// Returns `null` if no request has ever been submitted.
  Future<VerificationRequestModel?> getVerificationStatus(
    String doctorId,
  ) async {
    final snapshot = await _firestore
        .collection('verification_requests')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final docs = snapshot.docs.toList()
      ..sort((a, b) => _submittedAt(b).compareTo(_submittedAt(a)));

    return VerificationRequestModel.fromFirestore(docs.first);
  }

  /// Exposes a real-time stream of the latest request for the given [doctorId].
  Stream<VerificationRequestModel?> getVerificationStatusStream(
    String doctorId,
  ) {
    return _firestore
        .collection('verification_requests')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final docs = snapshot.docs.toList()
            ..sort((a, b) => _submittedAt(b).compareTo(_submittedAt(a)));
          return VerificationRequestModel.fromFirestore(docs.first);
        });
  }

  DateTime _submittedAt(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final raw = data['submittedAt'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ---------------------------------------------------------------------------
  // Admin Operations
  // ---------------------------------------------------------------------------

  /// Exposes a real-time stream of all requests currently in a `'pending'` status.
  Stream<List<VerificationRequestModel>> getPendingRequests() {
    return _firestore
        .collection('verification_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.toList()
            ..sort((a, b) => _submittedAt(a).compareTo(_submittedAt(b)));
          return docs
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
    final now = DateTime.now();

    // 1. Fetch request details to copy credentials
    final requestDoc = await _firestore
        .collection('verification_requests')
        .doc(requestId)
        .get();
    final requestData = requestDoc.data();
    final specialty = requestData?['specialty'] as String? ?? '';
    final licenseNumber = requestData?['licenseNumber'] as String? ?? '';
    final hospital = requestData?['hospital'] as String? ?? '';
    final prefix = requestData?['prefix'] as String? ?? 'Dr.';
    final hpType = requestData?['hpType'] as String? ?? 'doctor';

    final batch = _firestore.batch();

    final requestRef = _firestore
        .collection('verification_requests')
        .doc(requestId);
    batch.update(requestRef, {
      'status': 'approved',
      'reviewedAt': Timestamp.fromDate(now),
      'reviewedBy': reviewerId,
      'rejectionReason': FieldValue.delete(), // clear rejection reason if any
    });

    final userRef = _firestore.collection('users').doc(doctorId);
    batch.update(userRef, {
      'verificationStatus': 'approved',
      'role': hpType, // Elevate/ensure role is doctor/nurse/pharmacist/etc.
      'specialty': specialty,
      'licenseNumber': licenseNumber,
      'hospital': hospital,
      'prefix': prefix,
      'hpType': hpType,
    });

    // 2. Log doctor approval in Audit Logs
    final auditRef = _firestore.collection('audit_logs').doc();
    batch.set(auditRef, {
      'id': auditRef.id,
      'action': 'doctor_approval',
      'userId': reviewerId,
      'userName': 'Admin',
      'details':
          'Approved doctor verification for Dr. ${requestData?['doctorName'] ?? doctorId}. Specialty: $specialty, License: $licenseNumber',
      'timestamp': FieldValue.serverTimestamp(),
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

    // Fetch request details for logging name
    final requestDoc = await _firestore
        .collection('verification_requests')
        .doc(requestId)
        .get();
    final requestData = requestDoc.data();

    final requestRef = _firestore
        .collection('verification_requests')
        .doc(requestId);
    batch.update(requestRef, {
      'status': 'rejected',
      'rejectionReason': reason,
      'reviewedAt': Timestamp.fromDate(now),
      'reviewedBy': reviewerId,
    });

    final userRef = _firestore.collection('users').doc(doctorId);
    batch.update(userRef, {'verificationStatus': 'rejected'});

    // Log doctor rejection in Audit Logs
    final auditRef = _firestore.collection('audit_logs').doc();
    batch.set(auditRef, {
      'id': auditRef.id,
      'action': 'doctor_rejection',
      'userId': reviewerId,
      'userName': 'Admin',
      'details':
          'Rejected doctor verification for Dr. ${requestData?['doctorName'] ?? doctorId}. Reason: $reason',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Fetches a specific verification request by [requestId].
  Future<VerificationRequestModel?> getVerificationRequestById(
    String requestId,
  ) async {
    final doc = await _firestore
        .collection('verification_requests')
        .doc(requestId)
        .get();
    if (!doc.exists) return null;
    return VerificationRequestModel.fromFirestore(doc);
  }
}
