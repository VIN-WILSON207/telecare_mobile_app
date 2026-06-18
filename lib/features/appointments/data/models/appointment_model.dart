import 'package:cloud_firestore/cloud_firestore.dart';

/// Appointment record stored in Firestore under /appointments.
class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String patientName;
  final String doctorName;
  final String patientEmail;
  final String doctorEmail;
  final String reason;
  final String status;
  final DateTime appointmentDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.doctorName,
    required this.patientEmail,
    required this.doctorEmail,
    required this.reason,
    this.status = 'pending',
    required this.appointmentDate,
    required this.createdAt,
    this.updatedAt,
    this.notes,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return AppointmentModel(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      doctorId: data['doctorId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      patientEmail: data['patientEmail'] as String? ?? '',
      doctorEmail: data['doctorEmail'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      appointmentDate: _parseDateTime(data['appointmentDate']),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? _parseDateTime(data['updatedAt']) : null,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'patientName': patientName,
      'doctorName': doctorName,
      'patientEmail': patientEmail,
      'doctorEmail': doctorEmail,
      'reason': reason,
      'status': status,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'notes': notes,
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? patientName,
    String? doctorName,
    String? patientEmail,
    String? doctorEmail,
    String? reason,
    String? status,
    DateTime? appointmentDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      patientEmail: patientEmail ?? this.patientEmail,
      doctorEmail: doctorEmail ?? this.doctorEmail,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
