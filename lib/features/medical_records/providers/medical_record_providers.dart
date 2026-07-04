import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/medical_record_model.dart';
import '../data/repositories/medical_record_repository.dart';

final medicalRecordRepositoryProvider = Provider<MedicalRecordRepository>((
  ref,
) {
  return MedicalRecordRepository();
});

final medicalRecordListProvider = StreamProvider.autoDispose
    .family<List<MedicalRecordModel>, MedicalRecordListQuery>((ref, query) {
      final repository = ref.watch(medicalRecordRepositoryProvider);
      return query.isDoctor
          ? repository.getDoctorMedicalRecords(query.userId)
          : repository.getPatientMedicalRecords(query.userId);
    });

final patientMedicalRecordsProvider = StreamProvider.autoDispose
    .family<List<MedicalRecordModel>, String>((ref, patientId) {
      return ref
          .watch(medicalRecordRepositoryProvider)
          .getPatientMedicalRecords(patientId);
    });

final doctorMedicalRecordsProvider = StreamProvider.autoDispose
    .family<List<MedicalRecordModel>, String>((ref, doctorId) {
      return ref
          .watch(medicalRecordRepositoryProvider)
          .getDoctorMedicalRecords(doctorId);
    });

final medicalRecordDetailsProvider = FutureProvider.autoDispose
    .family<MedicalRecordModel?, String>((ref, recordId) {
      return ref
          .watch(medicalRecordRepositoryProvider)
          .getMedicalRecord(recordId);
    });

final createMedicalRecordProvider = FutureProvider.autoDispose
    .family<String, MedicalRecordModel>((ref, record) {
      return ref
          .watch(medicalRecordRepositoryProvider)
          .createMedicalRecord(record);
    });

final uploadAttachmentProvider = FutureProvider.autoDispose
    .family<String, String>((ref, path) {
      return ref.watch(medicalRecordRepositoryProvider).uploadAttachment(path);
    });

class MedicalRecordListQuery {
  final String userId;
  final bool isDoctor;

  const MedicalRecordListQuery({required this.userId, required this.isDoctor});

  @override
  bool operator ==(Object other) {
    return other is MedicalRecordListQuery &&
        other.userId == userId &&
        other.isDoctor == isDoctor;
  }

  @override
  int get hashCode => Object.hash(userId, isDoctor);
}
