import '../../auth/data/models/user_model.dart';

class VerificationGuard {
  VerificationGuard._();

  /// Returns `true` if the user is a verified healthcare professional.
  static bool isHealthcareProfessionalVerified(UserModel user) {
    if (!user.role.isHealthcareProfessional) return false;
    return user.verificationStatus.toLowerCase() == 'approved';
  }

  // Backward-compatible alias (in case older code still references the old name).
  // Remove once the entire codebase is updated.
  static bool isDoctorVerified(UserModel user) =>
      isHealthcareProfessionalVerified(user);


  /// Returns `true` if the user is a healthcare professional and still needs verification.
  static bool requiresVerification(UserModel user) {
    if (!user.role.isHealthcareProfessional) return false;
    return user.verificationStatus.toLowerCase() != 'approved';
  }
}

