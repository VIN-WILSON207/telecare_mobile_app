import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

/// Repository that wraps Firebase Auth + Firestore user-profile operations.
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Auth state helpers
  // ---------------------------------------------------------------------------

  /// The currently signed-in Firebase user, or `null`.
  User? get currentUser => _firebaseAuth.currentUser;

  /// A real-time stream of auth-state changes (sign-in / sign-out).
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // ---------------------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------------------

  /// Creates a new Firebase Auth account **and** a Firestore user profile.
  ///
  /// Returns the created [UserModel].
  /// Throws [AuthException] on failure.
  Future<UserModel> registerWithEmailAndPassword({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    required DateTime dateOfBirth,
    required String gender,
  }) async {
    try {
      // 1. Create Firebase Auth account and wait for the credential.
      final credential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(const Duration(seconds: 20));

      final user = credential.user;
      if (user == null || user.uid.isEmpty) {
        throw AuthException(
          code: 'null-user',
          message: 'Registration succeeded but returned an invalid user.',
        );
      }

      // 2. Force Firebase Auth to settle locally before Firestore rules evaluate
      // request.auth for /users/{uid}.
      final activeUser = await _waitForActiveUser(user.uid);
      await activeUser.reload();
      final token = await activeUser.getIdToken(true);
      if (token == null || token.isEmpty) {
        throw const AuthException(
          code: 'missing-id-token',
          message: 'Firebase Auth did not return an active ID token.',
        );
      }

      final userModel = UserModel(
        uid: activeUser.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
        dateOfBirth: dateOfBirth,
        gender: gender.trim(),
        verificationStatus: 'unverified',
        createdAt: DateTime.now(),
      );

      // 3. Persist the profile in Firestore
      await _runWithFirestoreRetry(
        () => _createUserProfile(userModel),
      ).timeout(const Duration(seconds: 30));
      return userModel;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException {
      rethrow;
    } on FirebaseException catch (e) {
      throw AuthException(
        code: 'firestore-${e.code}',
        message: e.message ?? 'Firestore failed while saving your profile.',
      );
    } on TimeoutException {
      throw const AuthException(
        code: 'timeout',
        message: 'Registration took too long. Please try again.',
      );
    } catch (e) {
      throw AuthException(
        code: e is AuthException ? e.code : 'registration-failed',
        message: e.toString(),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  /// Signs in with email & password and returns the corresponding [UserModel]
  /// from Firestore.
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth
        .signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        )
        .timeout(const Duration(seconds: 20));

    final user = credential.user;
    if (user == null) {
      throw AuthException(
        code: 'null-user',
        message: 'Sign-in succeeded but returned a null user.',
      );
    }

    // Fetch the Firestore profile
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw const AuthException(
        code: 'missing-id-token',
        message: 'Firebase Auth did not return an active ID token.',
      );
    }

    final userModel = await _runWithFirestoreRetry(
      () => getUserProfile(user.uid),
    ).timeout(const Duration(seconds: 30));
    if (userModel == null) {
      throw AuthException(
        code: 'profile-not-found',
        message: 'No user profile found for this account.',
      );
    }

    return userModel;
  }

  // ---------------------------------------------------------------------------
  // Password reset
  // ---------------------------------------------------------------------------

  /// Sends a Firebase password-reset email.
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------

  /// Signs the current user out of Firebase Auth.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Firestore profile helpers
  // ---------------------------------------------------------------------------

  /// Writes a new user profile document to the `users` collection.
  Future<void> _createUserProfile(UserModel userModel) async {
    final map = userModel.toMap();
    map['createdAt'] =
        FieldValue.serverTimestamp(); // Use server-side timestamp
    await _firestore.collection('users').doc(userModel.uid).set(
          map,
          SetOptions(merge: true),
        );
  }

  /// Reads the Firestore profile for [uid]. Returns `null` if not found.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<User> _waitForActiveUser(String uid) async {
    final current = _firebaseAuth.currentUser;
    if (current != null && current.uid == uid) return current;

    final user = await _firebaseAuth.authStateChanges().firstWhere(
          (candidate) => candidate != null && candidate.uid == uid,
        ).timeout(const Duration(seconds: 8));

    if (user == null || user.uid.isEmpty) {
      throw const AuthException(
        code: 'auth-state-not-ready',
        message: 'Firebase Auth did not finish activating this session.',
      );
    }
    return user;
  }

  Future<T> _runWithFirestoreRetry<T>(Future<T> Function() operation) async {
    const delays = [
      Duration(milliseconds: 300),
      Duration(milliseconds: 900),
      Duration(seconds: 2),
    ];

    for (var attempt = 0; attempt <= delays.length; attempt++) {
      try {
        return await operation();
      } on FirebaseException catch (e) {
        final retryable = e.code == 'unavailable' ||
            e.code == 'deadline-exceeded' ||
            e.code == 'aborted';
        if (!retryable || attempt == delays.length) rethrow;
        await Future.delayed(delays[attempt]);
      }
    }

    return operation();
  }

  /// Returns a real-time stream of the user profile document.
  Stream<UserModel?> userProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  /// Updates specific fields on an existing Firestore profile.
  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  /// Updates a patient's health vitals in their Firestore document.
  Future<void> updatePatientVitals({
    required String uid,
    required String bloodPressure,
    required String weight,
    required String height,
    required String bloodGroup,
    required String pulse,
    required String temperature,
  }) async {
    final parsedPulse = int.tryParse(pulse.trim());
    final parsedWeight = double.tryParse(weight.trim());
    final parsedHeight = double.tryParse(height.trim());
    final parsedTemp = double.tryParse(temperature.trim());
    final cleanBp = bloodPressure.trim().isEmpty ? null : bloodPressure.trim();
    final cleanBg = bloodGroup.trim().isEmpty ? null : bloodGroup.trim();

    await _firestore.collection('users').doc(uid).update({
      'bloodPressure': cleanBp,
      'weight': parsedWeight,
      'height': parsedHeight,
      'bloodGroup': cleanBg,
      'pulse': parsedPulse,
      'temperature': parsedTemp,
    });
  }
}

/// A lightweight exception for auth-layer errors that don't originate from
/// Firebase (e.g. null user, missing profile).
class AuthException implements Exception {
  final String code;
  final String message;

  const AuthException({required this.code, required this.message});

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}
