import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// Data model representing a TeleCare user stored in Firestore.
///
/// Provides full serialisation support:
/// - [toMap] / [fromMap] — Firestore documents (uses [Timestamp]).
/// - [toJson] / [fromJson] — JSON strings  (uses ISO-8601 dates).
/// - [toJsonMap] / [fromJsonMap] — plain JSON-safe maps.
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;

  /// Verification status for healthcare workers.
  /// Expected values: `'unverified'`, `'pending'`, `'verified'`, `'rejected'`.
  final String verificationStatus;

  /// URL pointing to the user's profile image in cloud storage.
  final String? profileImage;

  /// Timestamp of when the account was created.
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.verificationStatus = 'unverified',
    this.profileImage,
    required this.createdAt,
  });

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  /// Returns a new [UserModel] with the given fields replaced.
  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    String? verificationStatus,
    String? profileImage,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Firestore serialisation  (Map<String, dynamic>)
  // ---------------------------------------------------------------------------

  /// Converts this model to a Firestore-compatible map.
  ///
  /// [createdAt] is stored as a Firestore [Timestamp] so server-side
  /// queries and ordering work correctly.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role.value,
      'verificationStatus': verificationStatus,
      'profileImage': profileImage,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a [UserModel] from a Firestore document snapshot.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String? ?? 'patient'),
      verificationStatus:
          data['verificationStatus'] as String? ?? 'unverified',
      profileImage: data['profileImage'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Creates a [UserModel] from a plain map (Firestore or local).
  ///
  /// Handles [createdAt] being either a Firestore [Timestamp] or an
  /// ISO-8601 string for resilience.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String? ?? 'patient'),
      verificationStatus:
          map['verificationStatus'] as String? ?? 'unverified',
      profileImage: map['profileImage'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  // ---------------------------------------------------------------------------
  // JSON serialisation  (String)
  // ---------------------------------------------------------------------------

  /// Encodes this model to a JSON string.
  ///
  /// [createdAt] is stored as an ISO-8601 string for portability across
  /// REST APIs and local storage.
  String toJson() => json.encode(toJsonMap());

  /// Creates a [UserModel] from a JSON string.
  factory UserModel.fromJson(String source) =>
      UserModel.fromJsonMap(json.decode(source) as Map<String, dynamic>);

  /// Converts this model to a plain JSON-safe map (no Firestore types).
  Map<String, dynamic> toJsonMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role.value,
      'verificationStatus': verificationStatus,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a [UserModel] from a JSON-safe map.
  factory UserModel.fromJsonMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String? ?? 'patient'),
      verificationStatus:
          map['verificationStatus'] as String? ?? 'unverified',
      profileImage: map['profileImage'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & debugging
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.fullName == fullName &&
        other.email == email &&
        other.phone == phone &&
        other.role == role &&
        other.verificationStatus == verificationStatus &&
        other.profileImage == profileImage &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        uid,
        fullName,
        email,
        phone,
        role,
        verificationStatus,
        profileImage,
        createdAt,
      );

  @override
  String toString() {
    return 'UserModel(uid: $uid, fullName: $fullName, email: $email, '
        'phone: $phone, role: ${role.value}, '
        'verificationStatus: $verificationStatus, '
        'profileImage: $profileImage, createdAt: $createdAt)';
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Safely parses a [dynamic] value into a [DateTime].
  ///
  /// Supports Firestore [Timestamp], ISO-8601 [String], and falls back to
  /// [DateTime.now] when the value is `null` or unrecognised.
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
