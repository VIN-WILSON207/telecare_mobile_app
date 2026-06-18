import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a doctor's professional credential verification request.
class VerificationRequestModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String nationalIdUrl;
  final String licenseUrl;

  /// Verification status: `'pending'`, `'approved'`, or `'rejected'`.
  final String status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  const VerificationRequestModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.nationalIdUrl,
    required this.licenseUrl,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  VerificationRequestModel copyWith({
    String? id,
    String? doctorId,
    String? doctorName,
    String? nationalIdUrl,
    String? licenseUrl,
    String? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return VerificationRequestModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      nationalIdUrl: nationalIdUrl ?? this.nationalIdUrl,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  // ---------------------------------------------------------------------------
  // Firestore Serialization
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'nationalIdUrl': nationalIdUrl,
      'licenseUrl': licenseUrl,
      'status': status,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  factory VerificationRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VerificationRequestModel.fromMap(data, id: doc.id);
  }

  factory VerificationRequestModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return VerificationRequestModel(
      id: id ?? map['id'] as String? ?? '',
      doctorId: map['doctorId'] as String? ?? '',
      doctorName: map['doctorName'] as String? ?? '',
      nationalIdUrl: map['nationalIdUrl'] as String? ?? '',
      licenseUrl: map['licenseUrl'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      submittedAt: _parseDateTime(map['submittedAt']),
      reviewedAt: map['reviewedAt'] != null ? _parseDateTime(map['reviewedAt']) : null,
      reviewedBy: map['reviewedBy'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // JSON Serialization
  // ---------------------------------------------------------------------------

  String toJson() => json.encode(toJsonMap());

  factory VerificationRequestModel.fromJson(String source) =>
      VerificationRequestModel.fromJsonMap(json.decode(source) as Map<String, dynamic>);

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'nationalIdUrl': nationalIdUrl,
      'licenseUrl': licenseUrl,
      'status': status,
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  factory VerificationRequestModel.fromJsonMap(Map<String, dynamic> map) {
    return VerificationRequestModel(
      id: map['id'] as String? ?? '',
      doctorId: map['doctorId'] as String? ?? '',
      doctorName: map['doctorName'] as String? ?? '',
      nationalIdUrl: map['nationalIdUrl'] as String? ?? '',
      licenseUrl: map['licenseUrl'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      submittedAt: DateTime.parse(map['submittedAt'] as String),
      reviewedAt: map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt'] as String) : null,
      reviewedBy: map['reviewedBy'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  @override
  String toString() {
    return 'VerificationRequestModel(id: $id, doctorId: $doctorId, doctorName: $doctorName, '
        'nationalIdUrl: $nationalIdUrl, licenseUrl: $licenseUrl, status: $status, '
        'submittedAt: $submittedAt, reviewedAt: $reviewedAt, reviewedBy: $reviewedBy, '
        'rejectionReason: $rejectionReason)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VerificationRequestModel &&
        other.id == id &&
        other.doctorId == doctorId &&
        other.doctorName == doctorName &&
        other.nationalIdUrl == nationalIdUrl &&
        other.licenseUrl == licenseUrl &&
        other.status == status &&
        other.submittedAt == submittedAt &&
        other.reviewedAt == reviewedAt &&
        other.reviewedBy == reviewedBy &&
        other.rejectionReason == rejectionReason;
  }

  @override
  int get hashCode => Object.hash(
        id,
        doctorId,
        doctorName,
        nationalIdUrl,
        licenseUrl,
        status,
        submittedAt,
        reviewedAt,
        reviewedBy,
        rejectionReason,
      );
}
