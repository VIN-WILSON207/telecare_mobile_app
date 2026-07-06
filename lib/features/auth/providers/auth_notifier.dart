import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;

import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_role.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../../admin/dev_admin_access.dart';
import 'auth_providers.dart';
import 'auth_state.dart';

/// A [Notifier] that manages Auth state, Session timeouts, and First-install logic.
class AuthNotifier extends Notifier<AuthState> with WidgetsBindingObserver {
  static const _lastActivityKey = 'last_activity_timestamp';
  static const _isFirstInstallKey = 'is_first_install';
  static const _operationTimeout = Duration(seconds: 25);

  @override
  AuthState build() {
    debugPrint('[AuthNotifier] build()');
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));

    // Initialize in a microtask to avoid blocking the initial build
    Future.microtask(() => _initializeAuth());
    return const AuthLoading();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[AuthNotifier] Lifecycle: $state');
    if (state == AppLifecycleState.resumed) {
      _checkSessionTimeout();
    } else if (state == AppLifecycleState.paused) {
      updateActivity();
    }
  }

  /// Combined logic for First Install, Session Timeout, and Auth Check.
  Future<void> _initializeAuth() async {
    debugPrint('[AuthNotifier] _initializeAuth started');
    try {
      final prefs = ref.read(sharedPreferencesProvider);

      // 1. Check First Install
      final isFirstInstall = prefs.getBool(_isFirstInstallKey) ?? true;
      if (isFirstInstall) {
        debugPrint('[AuthNotifier] First Install logic: Showing splash.');
        state =
            const AuthSplash(); // Let the router know we are in splash state
        return;
      }

      // 2. Check Session Timeout (30 minutes)
      final sessionExpired = await _checkSessionTimeout();
      if (sessionExpired) {
        debugPrint('[AuthNotifier] Session expired at startup.');
        return; // state already set in _checkSessionTimeout
      }

      // 3. Regular Firebase Auth Check
      final firebaseUser = _repository.currentUser;
      if (firebaseUser != null) {
        debugPrint(
          '[AuthNotifier] User ${firebaseUser.uid} found. Fetching profile...',
        );
        final profile = await _repository
            .getUserProfile(firebaseUser.uid)
            .timeout(const Duration(seconds: 4), onTimeout: () => null);

        if (profile != null) {
          debugPrint('[AuthNotifier] Profile loaded. Authenticated.');
          state = AuthAuthenticated(profile);
          await updateActivity();
          return;
        }
      }

      debugPrint('[AuthNotifier] No session/user. Unauthenticated.');
      state = const AuthUnauthenticated();
    } catch (e) {
      debugPrint('[AuthNotifier] Init fatal error: $e');
      state = const AuthUnauthenticated();
    }
  }

  /// Sets state to Unauthenticated and returns true if session expired.
  Future<bool> _checkSessionTimeout() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final lastActivityStr = prefs.getString(_lastActivityKey);

      if (lastActivityStr != null) {
        final lastActivity = DateTime.parse(lastActivityStr);
        final difference = DateTime.now().difference(lastActivity);

        if (difference.inMinutes >= 30) {
          debugPrint(
            '[AuthNotifier] Session expired: ${difference.inMinutes} mins.',
          );
          await logout(); // Forces unauthenticated state
          return true;
        }
      }
    } catch (e) {
      debugPrint('[AuthNotifier] Session check error: $e');
    }
    return false;
  }

  /// Refreshes the last active timestamp.
  Future<void> updateActivity() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_lastActivityKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthLoading();
    // Yield to the UI so AuthLoading renders before the Firebase call starts
    await Future.delayed(Duration.zero);
    try {
      final user = await _repository
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(_operationTimeout);

      // Check if user is active
      if (!user.isActive) {
        await _repository.signOut();
        state = const AuthError(
          'This account has been deactivated. Please contact support.',
        );
        return;
      }

      // Create Audit Log for Login
      try {
        final auditRef = ref
            .read(firestoreProvider)
            .collection('audit_logs')
            .doc();
        await auditRef
            .set({
              'id': auditRef.id,
              'action': 'login',
              'userId': user.uid,
              'userName': user.fullName,
              'details': 'User logged in successfully',
              'timestamp': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 8));
      } catch (auditError) {
        debugPrint(
          '[AuthNotifier] Failed to write login audit log: $auditError',
        );
      }

      await updateActivity();
      state = AuthAuthenticated(user);
    } on FirebaseAuthException catch (e) {
      state = AuthError(_mapFirebaseError(e.code));
    } on TimeoutException {
      state = const AuthError(
        'The request is taking too long. Please check your connection and try again.',
      );
    } on AuthException catch (e) {
      if (_isFirestoreTransient(e.code) &&
          await _authenticateDevAdminFallback()) {
        return;
      }
      state = AuthError(_mapFirebaseError(e.code));
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> forgotPassword({required String email}) async {
    state = const AuthLoading();
    try {
      await _repository.sendPasswordResetEmail(email: email);
      state = const AuthPasswordResetSent();
    } on FirebaseAuthException catch (e) {
      state = AuthError(_mapFirebaseError(e.code));
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    required DateTime dateOfBirth,
    required String gender,
  }) async {
    state = const AuthLoading();
    // Yield to the UI so AuthLoading renders before the Firebase call starts
    await Future.delayed(Duration.zero);
    try {
      final user = await _repository
          .registerWithEmailAndPassword(
            fullName: fullName,
            email: email,
            password: password,
            phone: phone,
            role: role,
            dateOfBirth: dateOfBirth,
            gender: gender,
          )
          .timeout(_operationTimeout);

      // Create Audit Log for Registration
      try {
        final auditRef = ref
            .read(firestoreProvider)
            .collection('audit_logs')
            .doc();
        await auditRef
            .set({
              'id': auditRef.id,
              'action': 'registration',
              'userId': user.uid,
              'userName': user.fullName,
              'details':
                  'User registered successfully with role: ${user.role.value}',
              'timestamp': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 8));
      } catch (auditError) {
        debugPrint(
          '[AuthNotifier] Failed to write registration audit log: $auditError',
        );
      }

      await updateActivity();

      // Sign out since createUserWithEmailAndPassword signs the user in on the client.
      await _repository.signOut();

      state = const AuthRegistrationSuccess();
    } on FirebaseAuthException catch (e) {
      state = AuthError(_mapFirebaseError(e.code));
    } on TimeoutException {
      state = const AuthError(
        'The request is taking too long. Please check your connection and try again.',
      );
    } on AuthException catch (e) {
      state = AuthError(_mapFirebaseError(e.code));
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Send OTP to the given phone number via a generated mock code for development.
  Future<void> sendPhoneOtp({required String phone}) async {
    state = const AuthLoading();
    try {
      // Simulate network latency
      await Future.delayed(const Duration(milliseconds: 600));

      // Generate a 6-digit random code
      final generatedCode = List.generate(
        6,
        (_) => math.Random().nextInt(10).toString(),
      ).join();
      debugPrint(
        '[AuthNotifier] DEVELOPMENT ONLY: Generated Phone OTP code for $phone is: $generatedCode',
      );

      // Pass the code as verificationId so we can check it in verifyPhoneOtp
      state = AuthOtpSent(verificationId: generatedCode, phone: phone);
    } catch (e) {
      state = AuthError('Failed to generate mock OTP: ${e.toString()}');
    }
  }

  /// Verify the OTP code entered by the user.
  Future<void> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    state = const AuthLoading();
    try {
      // Simulate network verification latency
      await Future.delayed(const Duration(milliseconds: 600));

      if (smsCode == verificationId) {
        final auth = ref.read(firebaseAuthProvider);
        final uid = auth.currentUser?.uid;
        if (uid != null) {
          final profile = await _repository.getUserProfile(uid);
          if (profile != null) {
            await updateActivity();
            state = AuthAuthenticated(profile);
            return;
          }
        }
        state = const AuthPhoneVerified();
      } else {
        state = const AuthError('The OTP code is incorrect. Please try again.');
      }
    } catch (e) {
      state = AuthError('OTP verification failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove(_lastActivityKey);
      await _repository.signOut().catchError((_) {});
    } finally {
      state = const AuthUnauthenticated();
    }
  }

  Future<bool> _authenticateDevAdminFallback() async {
    final firebaseUser = _repository.currentUser;
    if (!isDevAdminEmail(firebaseUser?.email)) return false;

    await updateActivity();
    state = AuthAuthenticated(
      UserModel(
        uid: firebaseUser!.uid,
        fullName: 'TeleCare Admin',
        email: firebaseUser.email ?? devAdminEmail,
        phone: '',
        role: UserRole.admin,
        verificationStatus: 'approved',
        createdAt: DateTime.now(),
        isActive: true,
      ),
    );
    return true;
  }

  bool _isFirestoreTransient(String code) {
    return code == 'firestore-unavailable' ||
        code == 'firestore-deadline-exceeded' ||
        code == 'firestore-aborted' ||
        code == 'firestore-unknown';
  }

  /// Marks the first-install splash as complete and moves to unauthenticated.
  Future<void> completeSplash() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(_isFirstInstallKey, false);
      state = const AuthUnauthenticated();
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  /// Updates the user profile inside the authenticated state.
  void updateAuthenticatedUser(UserModel updatedUser) {
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(updatedUser);
    }
  }

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
      case 'firestore-unavailable':
        return 'Firestore is temporarily unavailable. Please retry in a moment.';
      case 'firestore-deadline-exceeded':
      case 'firestore-aborted':
      case 'firestore-unknown':
        return 'Firestore could not be reached reliably. Please check your connection and retry.';
      case 'firestore-permission-denied':
        return 'Firestore blocked this action. Check that your /users/{uid} rule allows the signed-in user to write their own profile.';
      case 'auth-state-not-ready':
        return 'Firebase is still activating your account. Please retry registration.';
      case 'missing-id-token':
        return 'Firebase Auth created the session but did not finish issuing an ID token. Please retry.';
      case 'timeout':
        return 'The request is taking too long. Please check your connection and try again.';
      case 'firestore-write-error':
        return 'Your account was created, but TeleCare could not save your profile. Check Firestore rules/network and try again.';
      case 'invalid-phone-number':
        return 'The phone number is invalid. Include country code (e.g. +237).';
      case 'invalid-verification-code':
        return 'The OTP code is incorrect. Please try again.';
      case 'session-expired':
        return 'OTP session expired. Please request a new code.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
