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
        .where('role', whereIn: [
          'doctor',
          'nurse',
          'lab_technician',
          'pharmacist',
          'physiotherapist'
        ])
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
        .map((snapshot) {
      final list = snapshot.docs
          .map(AppointmentModel.fromFirestore)
          .toList();
      _autoCompletePastAppointments(list);
      return list;
    });
  }

  Stream<List<AppointmentModel>> appointmentsForDoctor(String doctorId) {
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('appointmentDate', descending: false)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map(AppointmentModel.fromFirestore)
          .toList();
      _autoCompletePastAppointments(list);
      return list;
    });
  }

  void _autoCompletePastAppointments(List<AppointmentModel> list) {
    final now = DateTime.now();
    for (final app in list) {
      if (app.status == 'approved' &&
          now.difference(app.appointmentDate).inHours >= 1) {
        updateAppointmentStatus(app.id, status: 'completed');
      } else if (app.status == 'pending' && now.isAfter(app.appointmentDate)) {
        updateAppointmentStatus(app.id,
            status: 'completed', notes: 'Expired pending request');
      }
    }
  }

  Future<void> updateAppointmentStatus(
    String appointmentId, {
    required String status,
    String? notes,
  }) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': status,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      // ignore: use_null_aware_elements
      if (notes != null) 'notes': notes,
    });
  }
}
