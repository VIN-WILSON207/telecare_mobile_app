/// Thrown when Firestore fails to write a new consultation document.
class ConsultationCreationException implements Exception {
  final Object? cause;
  const ConsultationCreationException({this.cause});

  @override
  String toString() => 'ConsultationCreationException: $cause';
}

/// Thrown when a consultation with the same appointmentId already exists.
class DuplicateConsultationException implements Exception {
  final String appointmentId;
  const DuplicateConsultationException({required this.appointmentId});

  @override
  String toString() =>
      'DuplicateConsultationException: appointmentId=$appointmentId';
}

/// Thrown when a join is attempted with an empty or absent roomId.
class InvalidRoomException implements Exception {
  const InvalidRoomException();

  @override
  String toString() => 'InvalidRoomException: roomId is empty or absent';
}
