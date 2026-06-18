import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/data/models/user_model.dart';
import '../models/appointment_model.dart';

class AppointmentRepository {
  final FirebaseFirestore _firestore;

  AppointmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<UserModel>> getVerifiedDoctors() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('verificationStatus', isEqualTo: 'approved')
        .get();

    return snapshot.docs.map(UserModel.fromFirestore).toList();
  }

  Future<String> createAppointment({
    required String patientId,
    required String doctorId,
    required String patientName,
    required String doctorName,
    required String patientEmail,
    required String doctorEmail,
    required String reason,
    required DateTime appointmentDate,
    String status = 'pending',
    String? notes,
  }) async {
    final now = DateTime.now();
    final ref = await _firestore.collection('appointments').add({
      'patientId': patientId,
      'doctorId': doctorId,
      'patientName': patientName,
      'doctorName': doctorName,
      'patientEmail': patientEmail,
      'doctorEmail': doctorEmail,
      'reason': reason,
      'status': status,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'notes': notes,
    });

    return ref.id;
  }

  Stream<List<AppointmentModel>> appointmentsForPatient(String patientId) {
    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('appointmentDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(AppointmentModel.fromFirestore)
            .toList());
  }

  Stream<List<AppointmentModel>> appointmentsForDoctor(String doctorId) {
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('appointmentDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(AppointmentModel.fromFirestore)
            .toList());
  }

  Future<void> updateAppointmentStatus(
    String appointmentId, {
    required String status,
    String? notes,
  }) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': status,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      if (notes != null) 'notes': notes,
    });
  }
}
