import 'package:cloud_firestore/cloud_firestore.dart';

/// Sentinel object used in [ConsultationModel.copyWith] to distinguish between
/// "caller did not pass the argument" and "caller explicitly passed null".
const Object _sentinel = Object();

/// Consultation record stored in Firestore under /consultations.
class ConsultationModel {
  final String id;
  final String appointmentId;
  final String doctorId;
  final String patientId;
  final String roomId;

  /// One of: "scheduled", "active", "completed", "cancelled"
  final String status;

  /// One of: "video", "audio_only"
  final String mode;

  /// Null until the consultation is joined.
  final DateTime? startedAt;

  /// Null until the consultation is ended.
  final DateTime? endedAt;

  /// Floor minutes, >= 0
  final int duration;

  final DateTime createdAt;

  const ConsultationModel({
    required this.id,
    required this.appointmentId,
    required this.doctorId,
    required this.patientId,
    required this.roomId,
    this.status = 'scheduled',
    this.mode = 'video',
    this.startedAt,
    this.endedAt,
    this.duration = 0,
    required this.createdAt,
  });

  factory ConsultationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return ConsultationModel(
      id: doc.id,
      appointmentId: data['appointmentId'] as String? ?? '',
      doctorId: data['doctorId'] as String? ?? '',
      patientId: data['patientId'] as String? ?? '',
      roomId: data['roomId'] as String? ?? '',
      status: data['status'] as String? ?? 'scheduled',
      mode: data['mode'] as String? ?? 'video',
      startedAt: _parseNullableDateTime(data['startedAt']),
      endedAt: _parseNullableDateTime(data['endedAt']),
      duration: data['duration'] as int? ?? 0,
      createdAt: _parseDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'doctorId': doctorId,
      'patientId': patientId,
      'roomId': roomId,
      'status': status,
      'mode': mode,
      'startedAt':
          startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'duration': duration,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Returns a new [ConsultationModel] with the given fields replaced.
  ///
  /// Uses a sentinel pattern for [startedAt] and [endedAt] so callers can
  /// explicitly set them to `null`:
  ///
  /// ```dart
  /// // Keep existing startedAt:
  /// model.copyWith(status: 'active');
  ///
  /// // Explicitly clear startedAt:
  /// model.copyWith(startedAt: null);
  /// ```
  ConsultationModel copyWith({
    String? id,
    String? appointmentId,
    String? doctorId,
    String? patientId,
    String? roomId,
    String? status,
    String? mode,
    Object? startedAt = _sentinel,
    Object? endedAt = _sentinel,
    int? duration,
    DateTime? createdAt,
  }) {
    return ConsultationModel(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      roomId: roomId ?? this.roomId,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      startedAt: startedAt == _sentinel
          ? this.startedAt
          : startedAt as DateTime?,
      endedAt: endedAt == _sentinel ? this.endedAt : endedAt as DateTime?,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConsultationModel &&
        other.id == id &&
        other.appointmentId == appointmentId &&
        other.doctorId == doctorId &&
        other.patientId == patientId &&
        other.roomId == roomId &&
        other.status == status &&
        other.mode == mode &&
        other.startedAt == startedAt &&
        other.endedAt == endedAt &&
        other.duration == duration &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        appointmentId,
        doctorId,
        patientId,
        roomId,
        status,
        mode,
        startedAt,
        endedAt,
        duration,
        createdAt,
      );

  @override
  String toString() {
    return 'ConsultationModel('
        'id: $id, '
        'appointmentId: $appointmentId, '
        'doctorId: $doctorId, '
        'patientId: $patientId, '
        'roomId: $roomId, '
        'status: $status, '
        'mode: $mode, '
        'startedAt: $startedAt, '
        'endedAt: $endedAt, '
        'duration: $duration, '
        'createdAt: $createdAt'
        ')';
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) return DateTime.parse(value);
    return null;
  }
}
