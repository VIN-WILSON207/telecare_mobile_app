/// Represents the role of a user within the TeleCare platform.
enum UserRole {
  patient,
  doctor,
  nurse,
  labTechnician,
  pharmacist,
  physiotherapist,
  admin;

  /// Converts a raw Firestore string into a [UserRole].
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'doctor':
        return UserRole.doctor;
      case 'nurse':
        return UserRole.nurse;
      case 'labtechnician':
      case 'lab_technician':
      case 'lab technician':
        return UserRole.labTechnician;
      case 'pharmacist':
        return UserRole.pharmacist;
      case 'physiotherapist':
      case 'physio':
        return UserRole.physiotherapist;
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
      case UserRole.nurse:
        return 'nurse';
      case UserRole.labTechnician:
        return 'lab_technician';
      case UserRole.pharmacist:
        return 'pharmacist';
      case UserRole.physiotherapist:
        return 'physiotherapist';
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
      case UserRole.nurse:
        return 'Nurse';
      case UserRole.labTechnician:
        return 'Lab Technician';
      case UserRole.pharmacist:
        return 'Pharmacist';
      case UserRole.physiotherapist:
        return 'Physiotherapist';
      case UserRole.admin:
        return 'Admin';
      case UserRole.patient:
        return 'Patient';
    }
  }

  /// Returns the prefix to use when presenting a professional's name.
  String get displayPrefix {
    switch (this) {
      case UserRole.doctor:
        return 'Dr.';
      case UserRole.nurse:
        return 'Nurse';
      case UserRole.labTechnician:
        return 'Lab Tech';
      case UserRole.pharmacist:
        return 'Pharm.';
      case UserRole.physiotherapist:
        return 'Physio.';
      case UserRole.admin:
      case UserRole.patient:
        return '';
    }
  }

  /// Returns true for roles that need healthcare professional verification.
  bool get isHealthcareProfessional {
    return this == UserRole.doctor ||
        this == UserRole.nurse ||
        this == UserRole.labTechnician ||
        this == UserRole.pharmacist ||
        this == UserRole.physiotherapist;
  }

  /// Returns true when this role should be sent through verification onboarding.
  bool get requiresVerification {
    return isHealthcareProfessional;
  }
}
