import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility to seed Firestore programmatically with sample data matching FIREBASE_COLLECTIONS.md.
class FirestoreSeeder {
  /// Seeds all Firestore collections with sample documents using stable IDs to prevent duplicate inserts.
  static Future<void> seed() async {
    final firestore = FirebaseFirestore.instance;

    // 1. Seed 'users' collection
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

    await firestore.collection('users').doc('sample_doctor_1').set({
      'uid': 'sample_doctor_1',
      'fullName': 'Dr. Sarah Chen',
      'email': 'sarah.chen@telecare.com',
      'phone': '+237611111111',
      'role': 'doctor',
      'dateOfBirth': Timestamp.fromDate(DateTime(1985, 8, 20)),
      'gender': 'female',
      'verificationStatus': 'approved',
      'profileImage': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=150&fit=crop',
      'createdAt': FieldValue.serverTimestamp(),
      'specialty': 'Cardiology',
      'licenseNumber': 'LIC-123456-CARD',
      'hospital': 'General Central Hospital',
      'isActive': true,
      'bloodPressure': '',
      'weight': '',
      'height': '',
      'bloodGroup': '',
      'pulse': '',
      'temperature': '',
    }, SetOptions(merge: true));

    await firestore.collection('users').doc('sample_patient_1').set({
      'uid': 'sample_patient_1',
      'fullName': 'Alex Rivera',
      'email': 'alex.rivera@telecare.com',
      'phone': '+237622222222',
      'role': 'patient',
      'dateOfBirth': Timestamp.fromDate(DateTime(1995, 10, 15)),
      'gender': 'male',
      'verificationStatus': 'approved',
      'profileImage': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&fit=crop',
      'createdAt': FieldValue.serverTimestamp(),
      'specialty': null,
      'licenseNumber': null,
      'hospital': null,
      'isActive': true,
      'bloodPressure': '118/76',
      'weight': '68 kg',
      'height': '175 cm',
      'bloodGroup': 'O+',
      'pulse': '72 bpm',
      'temperature': '36.9 C',
    }, SetOptions(merge: true));

    // 2. Seed 'verification_requests' collection
    await firestore.collection('verification_requests').doc('sample_verification_1').set({
      'id': 'sample_verification_1',
      'doctorId': 'sample_doctor_1',
      'doctorName': 'Dr. Sarah Chen',
      'nationalIdUrl': 'https://cloudinary.com/sample_id.jpg',
      'licenseUrl': 'https://cloudinary.com/sample_license.jpg',
      'status': 'approved',
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': 'sample_admin_1',
      'rejectionReason': null,
      'specialty': 'Cardiology',
      'licenseNumber': 'LIC-123456-CARD',
      'hospital': 'General Central Hospital',
    }, SetOptions(merge: true));

    // 3. Seed 'appointments' collection
    await firestore.collection('appointments').doc('sample_appointment_1').set({
      'patientId': 'sample_patient_1',
      'doctorId': 'sample_doctor_1',
      'patientName': 'Alex Rivera',
      'doctorName': 'Dr. Sarah Chen',
      'patientEmail': 'alex.rivera@telecare.com',
      'doctorEmail': 'sarah.chen@telecare.com',
      'reason': 'Regular hypertension follow-up consultation.',
      'status': 'completed',
      'appointmentDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'notes': 'Patient feels stable. Review vital logs.',
    }, SetOptions(merge: true));

    // 4. Seed 'consultations' collection
    await firestore.collection('consultations').doc('sample_consultation_1').set({
      'appointmentId': 'sample_appointment_1',
      'doctorId': 'sample_doctor_1',
      'patientId': 'sample_patient_1',
      'roomId': 'consultation-room-9988-7766',
      'status': 'completed',
      'mode': 'video',
      'startedAt': FieldValue.serverTimestamp(),
      'endedAt': FieldValue.serverTimestamp(),
      'duration': 15,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 5. Seed 'medical_records' collection
    await firestore.collection('medical_records').doc('sample_medical_record_1').set({
      'appointmentId': 'sample_appointment_1',
      'consultationId': 'sample_consultation_1',
      'doctorId': 'sample_doctor_1',
      'doctorName': 'Dr. Sarah Chen',
      'nurseName': 'Nurse Beatrice',
      'patientId': 'sample_patient_1',
      'patientName': 'Alex Rivera',
      'diagnosis': 'Stage 1 Hypertension (Controlled)',
      'symptoms': ['Mild headaches', 'Fatigue'],
      'treatmentPlan': 'Continue current exercises, stick to low-sodium nutrition plan.',
      'prescription': [
        {'medicine': 'Lisinopril', 'dosage': '10mg once daily', 'duration': '30 days'},
      ],
      'notes': 'Advised patient to record vitals at least twice a day.',
      'attachments': ['https://cloudinary.com/sample_report.pdf'],
      'status': 'submitted',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': 'sample_doctor_1',
    }, SetOptions(merge: true));

    // 6. Seed 'audit_logs' collection
    await firestore.collection('audit_logs').doc('sample_audit_log_1').set({
      'id': 'sample_audit_log_1',
      'action': 'registration',
      'userId': 'sample_patient_1',
      'userName': 'Alex Rivera',
      'details': 'New patient registered successfully with default vitals.',
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 7. Seed 'health_tips' collection
    await firestore.collection('health_tips').doc('sample_health_tip_1').set({
      'title': 'Managing Blood Pressure',
      'content': 'A low-sodium diet and 30 minutes of light walking daily helps keep blood pressure regulated.',
      'authorName': 'Dr. Sarah Chen',
      'authorId': 'sample_doctor_1',
      'authorRole': 'doctor',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
