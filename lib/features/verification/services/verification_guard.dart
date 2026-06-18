import '../../auth/data/models/user_model.dart';
import '../../auth/data/models/user_role.dart';

class VerificationGuard {
  VerificationGuard._();

  /// Returns `true` if the user is a doctor and has been fully approved/verified.
  static bool isDoctorVerified(UserModel user) {
    if (user.role != UserRole.doctor) return false;
    return user.verificationStatus.toLowerCase() == 'approved';
  }

  /// Returns `true` if the user is a doctor and is not yet approved/verified.
  static bool requiresVerification(UserModel user) {
    if (user.role != UserRole.doctor) return false;
    return user.verificationStatus.toLowerCase() != 'approved';
  }
}
