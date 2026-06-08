import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

/// Repository that wraps Firebase Auth + Firestore user-profile operations.
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
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
  }) async {
    // 1. Create Firebase Auth account
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw AuthException(
        code: 'null-user',
        message: 'Registration succeeded but returned a null user.',
      );
    }

    // 2. Build the user model
    final userModel = UserModel(
      uid: user.uid,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: role,
      verificationStatus: 'unverified',
      createdAt: DateTime.now(),
    );

    // 3. Persist the profile in Firestore
    await _createUserProfile(userModel);

    return userModel;
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
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw AuthException(
        code: 'null-user',
        message: 'Sign-in succeeded but returned a null user.',
      );
    }

    // Fetch the Firestore profile
    final userModel = await getUserProfile(user.uid);
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
    await _firestore
        .collection('users')
        .doc(userModel.uid)
        .set(userModel.toMap());
  }

  /// Reads the Firestore profile for [uid]. Returns `null` if not found.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
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
