import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, FirebaseException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_role.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_providers.dart';
import 'auth_state.dart';

/// A [Notifier] that manages the current [AuthState].
///
/// All auth operations (register, login, forgot-password, logout) funnel
/// through this notifier so the UI only needs to watch a single provider.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Check if a user is already signed in on construction.
    _checkCurrentUser();
    return const AuthInitial();
  }

  /// Convenience getter for the injected repository.
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  // ---------------------------------------------------------------------------
  // Initial check
  // ---------------------------------------------------------------------------

  Future<void> _checkCurrentUser() async {
    final firebaseUser = _repository.currentUser;
    if (firebaseUser != null) {
      try {
        final profile = await _repository.getUserProfile(firebaseUser.uid);
        if (profile != null) {
          state = AuthAuthenticated(profile);
        } else {
          state = const AuthUnauthenticated();
        }
      } catch (_) {
        state = const AuthUnauthenticated();
      }
    } else {
      state = const AuthUnauthenticated();
    }
  }

  // ---------------------------------------------------------------------------
  // Register
  // ---------------------------------------------------------------------------

  /// Registers a new user and transitions to [AuthAuthenticated].
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repository.registerWithEmailAndPassword(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      state = AuthAuthenticated(user);
    } on FirebaseAuthException catch (e) {
      state = AuthError(_mapFirebaseError(e.code));
    } on FirebaseException catch (e) {
      state = AuthError(_mapFirebaseError(e.code));
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  /// Signs in an existing user and transitions to [AuthAuthenticated].
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AuthAuthenticated(user);
    } on FirebaseAuthException catch (e) {
      state = AuthError(_mapFirebaseError(e.code));
    } on FirebaseException catch (e) {
      state = AuthError(_mapFirebaseError(e.code));
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Forgot password
  // ---------------------------------------------------------------------------

  /// Sends a password-reset email.
  Future<void> forgotPassword({required String email}) async {
    state = const AuthLoading();
    try {
      await _repository.sendPasswordResetEmail(email: email);
      state = const AuthPasswordResetSent();
    } on FirebaseAuthException catch (e) {
      state = AuthError(_mapFirebaseError(e.code));
    } on FirebaseException catch (e) {
      state = AuthError(_mapFirebaseError(e.code));
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  /// Signs the current user out and transitions to [AuthUnauthenticated].
  Future<void> logout() async {
    state = const AuthLoading();
    try {
      await _repository.signOut();
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Error mapping
  // ---------------------------------------------------------------------------

  /// Converts raw Firebase error codes into user-friendly messages.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email address is already registered.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      case 'weak-password':
        return 'The password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'profile-not-found':
        return 'User profile not found. Please contact support.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
