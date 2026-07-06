import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility to seed Firestore programmatically with sample data matching FIREBASE_COLLECTIONS.md.
class FirestoreSeeder {
  /// Seeds all Firestore collections with sample documents using stable IDs to prevent duplicate inserts.
  static Future<void> seed() async {
    final firestore = FirebaseFirestore.instance;

    // Delete dummy documents to ensure the database has no dummy users/data
    final dummyUsers = ['sample_doctor_1', 'sample_patient_1'];
    for (final uid in dummyUsers) {
      await firestore.collection('users').doc(uid).delete().catchError((_) {});
    }
    await firestore.collection('verification_requests').doc('sample_verification_1').delete().catchError((_) {});
    await firestore.collection('appointments').doc('sample_appointment_1').delete().catchError((_) {});
    await firestore.collection('consultations').doc('sample_consultation_1').delete().catchError((_) {});
    await firestore.collection('medical_records').doc('sample_medical_record_1').delete().catchError((_) {});
    await firestore.collection('audit_logs').doc('sample_audit_log_1').delete().catchError((_) {});
    await firestore.collection('health_tips').doc('sample_health_tip_1').delete().catchError((_) {});

    // 1. Seed 'users' collection (ONLY seed the admin)
    await firestore.collection('users').doc('sample_admin_1').set({
      'uid': 'sample_admin_1',
      'fullName': 'Abila Vin Wilson',
      'email': 'abilavinwilson@gmail.com',
      'phone': '+237600000000',
      'role': 'admin',
      'dateOfBirth': Timestamp.fromDate(DateTime(1990, 5, 12)),
      'gender': 'male',
      'verificationStatus': 'approved',
      'profileImage': null,
      'createdAt': FieldValue.serverTimestamp(),
      'specialty': null,
      'licenseNumber': null,
      'hospital': null,
      'isActive': true,
      'bloodPressure': '',
      'weight': '',
      'height': '',
      'bloodGroup': '',
      'pulse': '',
      'temperature': '',
    }, SetOptions(merge: true));
  }
}
