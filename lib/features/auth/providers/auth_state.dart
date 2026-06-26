import '../data/models/user_model.dart';

/// Sealed-class-style hierarchy representing every possible auth state.
///
/// Using a base class + subtypes lets the UI switch on the runtime type
/// and keeps the notifier logic clean.
abstract class AuthState {
  const AuthState();
}

/// Initial / idle — no operation in progress, no user signed in.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// An async auth operation is in progress (login, register, password reset).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// The user is authenticated and we have their Firestore profile.
class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}

/// A splash screen animation is currently playing (first install).
class AuthSplash extends AuthState {
  const AuthSplash();
}

/// No user is signed in.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An auth operation failed. [message] is user-facing.
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

/// A password-reset email was sent successfully.
class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

/// Firebase Phone Auth: SMS OTP has been sent to [phone].
/// [verificationId] is needed to confirm the code later.
class AuthOtpSent extends AuthState {
  final String verificationId;
  final String phone;
  const AuthOtpSent({required this.verificationId, required this.phone});
}

/// The phone number has been successfully verified via OTP.
class AuthPhoneVerified extends AuthState {
  const AuthPhoneVerified();
}
