import 'package:flutter_test/flutter_test.dart';
import 'package:telecare_mobile_app/features/auth/data/models/user_model.dart';
import 'package:telecare_mobile_app/features/auth/data/models/user_role.dart';
import 'verification_guard.dart';

void main() {
  group('VerificationGuard', () {
    test('requiresVerification returns true for unapproved healthcare roles', () {
      final doctor = UserModel(
        uid: '1',
        fullName: 'Doctor One',
        email: 'd@test.com',
        phone: '+237000000001',
        role: UserRole.doctor,
        verificationStatus: 'pending',
        createdAt: DateTime(2026, 1, 1),
      );

      final nurse = UserModel(
        uid: '2',
        fullName: 'Nurse One',
        email: 'n@test.com',
        phone: '+237000000002',
        role: UserRole.nurse,
        verificationStatus: 'rejected',
        createdAt: DateTime(2026, 1, 1),
      );

      final labTech = UserModel(
        uid: '3',
        fullName: 'Lab Tech One',
        email: 'l@test.com',
        phone: '+237000000003',
        role: UserRole.labTechnician,
        verificationStatus: 'PENDING',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(VerificationGuard.requiresVerification(doctor), isTrue);
      expect(VerificationGuard.requiresVerification(nurse), isTrue);
      expect(VerificationGuard.requiresVerification(labTech), isTrue);
    });

    test('requiresVerification returns false for approved healthcare roles', () {
      final user = UserModel(
        uid: '1',
        fullName: 'Doctor Approved',
        email: 'p@test.com',
        phone: '+237000000004',
        role: UserRole.doctor,
        verificationStatus: 'approved',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(VerificationGuard.requiresVerification(user), isFalse);
    });

    test('requiresVerification returns false for non-healthcare roles', () {
      final patient = UserModel(
        uid: '1',
        fullName: 'Patient',
        email: 'pt@test.com',
        phone: '+237000000005',
        role: UserRole.patient,
        verificationStatus: 'pending',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(VerificationGuard.requiresVerification(patient), isFalse);
    });
  });
}


