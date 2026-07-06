import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

import '../../../../core/services/notification_service.dart';
import '../exceptions/consultation_exceptions.dart';
import '../models/consultation_model.dart';
import '../repositories/consultation_repository.dart';

class ConsultationService {
  ConsultationService({
    required ConsultationRepository repository,
    required NotificationService notificationService,
    JitsiMeet? jitsiMeet,
    Connectivity? connectivity,
  })  : _repository = repository,
        _notificationService = notificationService,
        _jitsiMeet = jitsiMeet ?? JitsiMeet(),
        _connectivity = connectivity ?? Connectivity();

  final ConsultationRepository _repository;
  final NotificationService _notificationService;
  final JitsiMeet _jitsiMeet;
  final Connectivity _connectivity;

  Connectivity get connectivity => _connectivity;

  /// Joins a consultation room via Jitsi Meet.
  ///
  /// Validates roomId, joins Jitsi, updates Firestore on success,
  /// reverts status on failure, and sends a notification to the patient.
  Future<void> joinRoom(
      ConsultationModel consultation, String displayName) async {
    // Requirement 8.2 — validate roomId before calling Jitsi
    if (consultation.roomId.isEmpty) {
      throw const InvalidRoomException();
    }

    var statusChangedByThisCall = false;

    try {
      final options = JitsiMeetConferenceOptions(
        room: consultation.roomId,
        userInfo: JitsiMeetUserInfo(
          displayName: displayName,
        ),
      );

      await _jitsiMeet.join(options);

      // Requirement 8.4 — update status to "active" only if it was "scheduled"
      if (consultation.status == 'scheduled') {
        statusChangedByThisCall = true;
        await _repository.joinConsultation(consultation.id);

        // Requirement 4 — send notification to patient
        try {
          final payload = NotificationService.buildConsultationStartedPayload(
            doctorName: displayName,
            consultationId: consultation.id,
            roomId: consultation.roomId,
          );
          await _notificationService.sendNotification(
            targetUserId: consultation.patientId,
            title: payload['title'] as String,
            body: payload['body'] as String,
            data: Map<String, String>.from(payload['data'] as Map),
          );
        } catch (e) {
          debugPrint(
              '[ConsultationService] Failed to send consultation started notification: $e');
        }
      }
    } catch (e) {
      if (e is InvalidRoomException) rethrow;

      // Requirement 8.5 — revert status if this call changed it
      if (statusChangedByThisCall) {
        try {
          await _repository.updateStatus(consultation.id, 'scheduled');
        } catch (revertError) {
          // Best-effort revert; log but don't throw
          debugPrint(
              '[ConsultationService] Failed to revert consultation status: $revertError');
        }
      }
      rethrow;
    }
  }

  /// Ends a consultation, recording endedAt and duration.
  ///
  /// Idempotent — if consultation is already completed, does nothing.
  /// Retries once on Firestore failure.
  Future<void> endConsultation(ConsultationModel consultation) async {
    // Requirement 9.2 — idempotency check
    if (consultation.status == 'completed') {
      debugPrint(
          '[ConsultationService] Consultation already completed. Skipping.');
      return;
    }

    final startedAt = consultation.startedAt ?? DateTime.now();

    // Requirement 9.4 — retry once on failure
    Exception? lastError;
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        await _repository.endConsultation(consultation.id, startedAt);
        if (consultation.appointmentId.isNotEmpty) {
          await _repository.updateAppointmentStatus(
              consultation.appointmentId, 'completed');
        }
        return;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        debugPrint(
            '[ConsultationService] endConsultation attempt ${attempt + 1} failed: $e');
        if (attempt == 0) {
          // Short pause before retry
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    // Requirement 9.5 — both attempts failed, rethrow for UI to handle
    throw lastError!;
  }

  /// Switches the consultation to audio-only mode.
  ///
  /// Updates Firestore mode field, then rejoins Jitsi with video disabled.
  Future<void> switchToAudioOnly(
      ConsultationModel consultation, String displayName) async {
    // Requirement 10.3 — update Firestore first
    await _repository.updateMode(consultation.id, 'audio_only');

    // Requirement 10.4 — rejoin Jitsi with video disabled via configOverrides
    try {
      final options = JitsiMeetConferenceOptions(
        room: consultation.roomId,
        userInfo: JitsiMeetUserInfo(displayName: displayName),
        configOverrides: {
          'startWithVideoMuted': true,
        },
      );
      await _jitsiMeet.join(options);
    } catch (e) {
      // Requirement 10.5 — on rejoin failure, keep mode="audio_only" in Firestore
      // and rethrow so UI can show retry prompt
      debugPrint('[ConsultationService] Jitsi rejoin (audio-only) failed: $e');
      rethrow;
    }
  }

  /// Switches the consultation back to video mode.
  ///
  /// Updates Firestore mode field, then rejoins Jitsi with video enabled.
  Future<void> switchToVideo(
      ConsultationModel consultation, String displayName) async {
    // Requirement 10.8 — update Firestore
    await _repository.updateMode(consultation.id, 'video');

    // Rejoin Jitsi with video enabled via configOverrides
    try {
      final options = JitsiMeetConferenceOptions(
        room: consultation.roomId,
        userInfo: JitsiMeetUserInfo(displayName: displayName),
        configOverrides: {
          'startWithVideoMuted': false,
        },
      );
      await _jitsiMeet.join(options);
    } catch (e) {
      debugPrint('[ConsultationService] Jitsi rejoin (video) failed: $e');
      rethrow;
    }
  }
}
