import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../appointments/data/models/appointment_model.dart';
import '../exceptions/consultation_exceptions.dart';
import '../models/consultation_model.dart';

class ConsultationRepository {
  final FirebaseFirestore _firestore;

  ConsultationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _consultations =>
      _firestore.collection('consultations');

  /// Creates a new consultation for the given [appointment].
  ///
  /// Throws [DuplicateConsultationException] if a consultation already exists
  /// for the appointment. Throws [ConsultationCreationException] on any
  /// Firestore error.
  ///
  /// Returns the Firestore document ID of the created consultation.
  Future<String> createConsultation(AppointmentModel appointment) async {
    try {
      // Check for existing consultation with the same appointmentId.
      final existing = await _consultations
          .where('appointmentId', isEqualTo: appointment.id)
          .where('doctorId', isEqualTo: appointment.doctorId)
          .get();

      if (existing.docs.isNotEmpty) {
        throw DuplicateConsultationException(appointmentId: appointment.id);
      }

      final roomId = const Uuid().v4();

      final docRef = await _consultations.add({
        'appointmentId': appointment.id,
        'doctorId': appointment.doctorId,
        'patientId': appointment.patientId,
        'roomId': roomId,
        'status': 'scheduled',
        'mode': 'video',
        'startedAt': null,
        'endedAt': null,
        'duration': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } on DuplicateConsultationException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ConsultationCreationException(cause: e);
    }
  }

  /// Marks a consultation as active and records the start time.
  Future<void> joinConsultation(String id) async {
    await _consultations.doc(id).update({
      'status': 'active',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Marks a consultation as completed, recording the end time and duration.
  ///
  /// [startedAt] is used to compute the floor-minute duration.
  Future<void> endConsultation(String id, DateTime startedAt) async {
    final now = DateTime.now();
    final duration = now.difference(startedAt).inSeconds ~/ 60;

    await _consultations.doc(id).update({
      'status': 'completed',
      'endedAt': Timestamp.fromDate(now),
      'duration': duration,
    });
  }

  /// Updates the call mode (e.g. "video" or "audio_only") of a consultation.
  Future<void> updateMode(String id, String mode) async {
    await _consultations.doc(id).update({'mode': mode});
  }

  /// Updates the status of a consultation document.
  Future<void> updateStatus(String id, String status) async {
    await _consultations.doc(id).update({'status': status});
  }

  /// Updates the status of an appointment document.
  Future<void> updateAppointmentStatus(String id, String status) async {
    await _firestore.collection('appointments').doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Watches a single consultation document by [id].
  ///
  /// Emits `null` when the document does not exist.
  Stream<ConsultationModel?> watchConsultation(String id) {
    return _consultations.doc(id).snapshots().map((snap) {
      if (!snap.exists) return null;
      return ConsultationModel.fromFirestore(snap);
    });
  }

  /// Watches all consultations where the user (identified by [uid]) is either
  /// the patient or the doctor.
  ///
  /// The two Firestore streams are merged and sorted by `createdAt` descending.
  Stream<List<ConsultationModel>> watchUserConsultations(String uid) {
    final controller = StreamController<List<ConsultationModel>>();

    List<ConsultationModel> patientDocs = [];
    List<ConsultationModel> doctorDocs = [];

    void emit() {
      final merged = [...patientDocs, ...doctorDocs];
      // De-duplicate by id in case a user is both doctor and patient.
      final seen = <String>{};
      final unique =
          merged.where((c) => seen.add(c.id)).toList();

      unique.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(unique);
    }

    final subA = _consultations
        .where('patientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        patientDocs = snap.docs.map(ConsultationModel.fromFirestore).toList();
        emit();
      },
      onError: controller.addError,
    );

    final subB = _consultations
        .where('doctorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        doctorDocs = snap.docs.map(ConsultationModel.fromFirestore).toList();
        emit();
      },
      onError: controller.addError,
    );

    controller.onCancel = () {
      subA.cancel();
      subB.cancel();
    };

    return controller.stream;
  }
}
