/// Represents the role of a user within the TeleCare platform.
enum UserRole {
  patient,
  doctor,
  admin;

  /// Converts a raw Firestore string into a [UserRole].
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'doctor':
        return UserRole.doctor;
      case 'admin':
        return UserRole.admin;
      case 'patient':
      default:
        return UserRole.patient;
    }
  }

  /// Returns the Firestore-safe string representation.
  String get value {
    switch (this) {
      case UserRole.doctor:
        return 'doctor';
      case UserRole.admin:
        return 'admin';
      case UserRole.patient:
        return 'patient';
    }
  }

  /// Human-readable display label.
  String get label {
    switch (this) {
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.admin:
        return 'Admin';
      case UserRole.patient:
        return 'Patient';
    }
  }
}
