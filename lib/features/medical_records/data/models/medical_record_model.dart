import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionItem {
  final String medicine;
  final String dosage;
  final String duration;

  const PrescriptionItem({
    required this.medicine,
    required this.dosage,
    required this.duration,
  });

  factory PrescriptionItem.fromMap(Map<String, dynamic> map) {
    return PrescriptionItem(
      medicine: map['medicine'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      duration: map['duration'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'medicine': medicine, 'dosage': dosage, 'duration': duration};
  }
}

class MedicalRecordModel {
  final String id;
  final String appointmentId;
  final String? consultationId;
  final String doctorId;
  final String doctorName;
  final String nurseName;
  final String patientId;
  final String patientName;
  final String diagnosis;
  final List<String> symptoms;
  final String treatmentPlan;
  final List<PrescriptionItem> prescription;
  final String notes;
  final List<String> attachments;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const MedicalRecordModel({
    required this.id,
    required this.appointmentId,
    this.consultationId,
    required this.doctorId,
    required this.doctorName,
    this.nurseName = '',
    required this.patientId,
    required this.patientName,
    required this.diagnosis,
    required this.symptoms,
    required this.treatmentPlan,
    required this.prescription,
    required this.notes,
    required this.attachments,
    this.status = 'submitted',
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory MedicalRecordModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final prescriptionData = data['prescription'];

    return MedicalRecordModel(
      id: doc.id,
      appointmentId: data['appointmentId'] as String? ?? '',
      consultationId: data['consultationId'] as String?,
      doctorId: data['doctorId'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      nurseName: data['nurseName'] as String? ?? '',
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      diagnosis: data['diagnosis'] as String? ?? '',
      symptoms: List<String>.from(data['symptoms'] as List? ?? const []),
      treatmentPlan: data['treatmentPlan'] as String? ?? '',
      prescription: prescriptionData is List
          ? prescriptionData
                .whereType<Map>()
                .map(
                  (item) =>
                      PrescriptionItem.fromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      notes: data['notes'] as String? ?? '',
      attachments: List<String>.from(data['attachments'] as List? ?? const []),
      status: data['status'] as String? ?? 'submitted',
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'consultationId': consultationId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'nurseName': nurseName,
      'patientId': patientId,
      'patientName': patientName,
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'treatmentPlan': treatmentPlan,
      'prescription': prescription.map((item) => item.toMap()).toList(),
      'notes': notes,
      'attachments': attachments,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  MedicalRecordModel copyWith({
    String? id,
    String? appointmentId,
    String? consultationId,
    String? doctorId,
    String? doctorName,
    String? nurseName,
    String? patientId,
    String? patientName,
    String? diagnosis,
    List<String>? symptoms,
    String? treatmentPlan,
    List<PrescriptionItem>? prescription,
    String? notes,
    List<String>? attachments,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return MedicalRecordModel(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      consultationId: consultationId ?? this.consultationId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      nurseName: nurseName ?? this.nurseName,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      diagnosis: diagnosis ?? this.diagnosis,
      symptoms: symptoms ?? this.symptoms,
      treatmentPlan: treatmentPlan ?? this.treatmentPlan,
      prescription: prescription ?? this.prescription,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) return DateTime.parse(value);
    return DateTime.now();
  }
}
