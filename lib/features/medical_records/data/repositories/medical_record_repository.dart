import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../verification/services/cloudinary_service.dart';
import '../models/medical_record_model.dart';

class MedicalRecordRepository {
  final FirebaseFirestore _firestore;

  MedicalRecordRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection('medical_records');

  Future<String> createMedicalRecord(MedicalRecordModel record) async {
    final ref = await _records.add(record.toMap());
    return ref.id;
  }

  Future<void> updateMedicalRecord(MedicalRecordModel record) async {
    await _records.doc(record.id).update({
      ...record.toMap(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<MedicalRecordModel?> getMedicalRecord(String recordId) async {
    final doc = await _records.doc(recordId).get();
    if (!doc.exists) return null;
    return MedicalRecordModel.fromFirestore(doc);
  }

  Future<String> uploadAttachment(String filePath) {
    return CloudinaryService().uploadMedicalRecordAttachment(filePath);
  }

  Stream<List<MedicalRecordModel>> getPatientMedicalRecords(String patientId) {
    return _records
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(MedicalRecordModel.fromFirestore).toList(),
        );
  }

  Stream<List<MedicalRecordModel>> getDoctorMedicalRecords(String doctorId) {
    return _records
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(MedicalRecordModel.fromFirestore).toList(),
        );
  }
}
