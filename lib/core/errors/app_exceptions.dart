import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

/// Base class for all application-specific exceptions.
sealed class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: [$code] $message';
}

/// Exceptions related to Authentication.
class AuthException extends AppException {
  const AuthException(super.message, [super.code]);

  factory AuthException.fromFirebase(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthException(
          'No user found with this email.',
          'auth/user-not-found',
        );
      case 'wrong-password':
        return const AuthException(
          'Incorrect password. Please try again.',
          'auth/wrong-password',
        );
      case 'email-already-in-use':
        return const AuthException(
          'This email is already registered.',
          'auth/email-already-in-use',
        );
      case 'invalid-email':
        return const AuthException(
          'The email address is invalid.',
          'auth/invalid-email',
        );
      case 'weak-password':
        return const AuthException(
          'The password provided is too weak.',
          'auth/weak-password',
        );
      case 'user-disabled':
        return const AuthException(
          'This account has been disabled.',
          'auth/user-disabled',
        );
      case 'too-many-requests':
        return const AuthException(
          'Too many attempts. Please try again later.',
          'auth/too-many-requests',
        );
      default:
        return AuthException(e.message ?? 'Authentication failed.', e.code);
    }
  }
}

/// Exceptions related to Database operations.
class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.code]);

  factory DatabaseException.fromFirestore(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const DatabaseException(
          'You do not have permission to perform this action.',
          'db/permission-denied',
        );
      case 'unavailable':
        return const DatabaseException(
          'The service is temporarily unavailable. Please check your connection.',
          'db/unavailable',
        );
      case 'not-found':
        return const DatabaseException(
          'Requested resource was not found.',
          'db/not-found',
        );
      case 'deadline-exceeded':
        return const DatabaseException(
          'The operation timed out. Please try again.',
          'db/deadline-exceeded',
        );
      default:
        return DatabaseException(
          e.message ?? 'Database operation failed.',
          e.code,
        );
    }
  }
}

/// Exceptions related to Network/Connectivity.
class NetworkException extends AppException {
  const NetworkException([
    String message = 'Please check your internet connection.',
  ]) : super(message, 'network/unavailable');
}

/// Exceptions for Timeout operations.
class AppTimeoutException extends AppException {
  const AppTimeoutException([
    String message = 'The operation took too long to complete.',
  ]) : super(message, 'app/timeout');
}

/// Utility to wrap async calls with standard error handling.
Future<T> handleGuardedCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on FirebaseAuthException catch (e) {
    throw AuthException.fromFirebase(e);
  } on FirebaseException catch (e) {
    throw DatabaseException.fromFirestore(e);
  } on TimeoutException {
    throw const AppTimeoutException();
  } catch (e) {
    // AppException is sealed, so throw the concrete subtype.
    throw AppTimeoutException(e.toString());
  }
}
