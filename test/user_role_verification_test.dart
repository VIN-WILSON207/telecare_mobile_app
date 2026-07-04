import 'package:flutter_test/flutter_test.dart';
import 'package:telecare_mobile_app/features/auth/data/models/user_role.dart';

void main() {
  group('UserRole verification helpers', () {
    test('treats doctors, nurses, and lab technicians as healthcare professionals that need verification', () {
      expect(UserRole.doctor.requiresVerification, isTrue);
      expect(UserRole.nurse.requiresVerification, isTrue);
      expect(UserRole.labTechnician.requiresVerification, isTrue);
      expect(UserRole.patient.requiresVerification, isFalse);
      expect(UserRole.admin.requiresVerification, isFalse);
    });

    test('returns the right display prefix for healthcare professional roles', () {
      expect(UserRole.doctor.displayPrefix, 'Dr.');
      expect(UserRole.nurse.displayPrefix, 'Nurse');
      expect(UserRole.labTechnician.displayPrefix, 'Lab Tech');
      expect(UserRole.patient.displayPrefix, '');
    });
  });
}
