import 'package:flutter_test/flutter_test.dart';
import 'package:telecare_mobile_app/features/auth/data/models/user_model.dart';
import 'package:telecare_mobile_app/features/auth/data/models/user_role.dart';

void main() {
  group('UserModel', () {
    final now = DateTime.now();
    final user = UserModel(
      uid: '123',
      fullName: 'John Doe',
      email: 'john@example.com',
      phone: '670000000',
      role: UserRole.patient,
      createdAt: now,
    );

    test('toJsonMap contains all required fields', () {
      final map = user.toJsonMap();
      expect(map['uid'], '123');
      expect(map['fullName'], 'John Doe');
      expect(map['email'], 'john@example.com');
      expect(map['role'], 'patient');
    });

    test('fromJsonMap restores object correctly', () {
      final map = {
        'uid': '456',
        'fullName': 'Jane Smith',
        'email': 'jane@example.com',
        'phone': '680000000',
        'role': 'doctor',
        'createdAt': now.toIso8601String(),
        'verificationStatus': 'verified',
        'isActive': true,
      };
      final restored = UserModel.fromJsonMap(map);
      expect(restored.uid, '456');
      expect(restored.fullName, 'Jane Smith');
      expect(restored.role, UserRole.doctor);
      expect(restored.verificationStatus, 'verified');
    });

    test('copyWith updates fields correctly', () {
      final updated = user.copyWith(fullName: 'John Updated');
      expect(updated.fullName, 'John Updated');
      expect(updated.uid, user.uid);
      expect(updated.email, user.email);
    });
  });
}
