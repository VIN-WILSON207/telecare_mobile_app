import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_role.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../auth/providers/auth_state.dart';
import '../../data/exceptions/consultation_exceptions.dart';
import '../../data/models/consultation_model.dart';
import '../../providers/consultation_providers.dart';

import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class ConsultationScreen extends ConsumerStatefulWidget {
  final String consultationId;

  const ConsultationScreen({super.key, required this.consultationId});

  @override
  ConsumerState<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends ConsumerState<ConsultationScreen> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _sustainedTimer;
  ConnectivityResult? _lastConnectivity;
  bool _showingAudioDialog = false;
  bool _joining = false;
  bool _ending = false;
  Timer? _noAnswerTimer;
  bool _isAnswered = false;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
    _setInCall(true);
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _sustainedTimer?.cancel();
    _noAnswerTimer?.cancel();
    _setInCall(false);
    super.dispose();
  }

  void _setInCall(bool value) {
    try {
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthAuthenticated) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(authState.user.uid)
            .update({'inCall': value});
      }
    } catch (e) {
      debugPrint('Failed to set inCall: $e');
    }
  }

  Future<void> _handleCallTimeout(ConsultationModel consultation) async {
    if (mounted) {
      setState(() {
        _timedOut = true;
      });
    }

    try {
      await JitsiMeet().hangUp();
    } catch (e) {
      debugPrint('[ConsultationScreen] Jitsi hangUp failed: $e');
    }

    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('consultations').doc(consultation.id).update({
        'status': 'cancelled',
        'notes': 'No answer / Timeout',
      });
      if (consultation.appointmentId.isNotEmpty) {
        await firestore.collection('appointments').doc(consultation.appointmentId).update({
          'status': 'completed',
          'notes': 'Call not answered',
        });
      }
    } catch (e) {
      debugPrint('[ConsultationScreen] Firestore timeout update failed: $e');
    }

    if (mounted) {
      _showTimeoutDialog();
    }
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone_missed_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('No Answer'),
          ],
        ),
        content: const Text(
          'The call was not answered. Please try again after a few minutes.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/consultations');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrescriptionWaitingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: AppTheme.successColor),
            SizedBox(width: 8),
            Text('Consultation Ended', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This consultation has completed. Please wait for your healthcare professional to upload your digital prescription if your case requires one.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/home');
            },
            child: const Text('Go to Dashboard'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/prescriptions');
            },
            child: const Text('View Prescriptions'),
          ),
        ],
      ),
    );
  }

  // ── Connectivity monitoring ──────────────────────────────────────────────────

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final result =
        results.isNotEmpty ? results.first : ConnectivityResult.none;
    _lastConnectivity = result;
    _sustainedTimer?.cancel();

    // Get current consultation from provider
    final consultation =
        ref.read(consultationStreamProvider(widget.consultationId)).value;
    if (consultation == null || consultation.status != 'active') return;



    if (result == ConnectivityResult.none) {
      // Req 10.6 — auto-switch after 5 s with no connectivity
      _sustainedTimer = Timer(const Duration(seconds: 5), () {
        if (_lastConnectivity == ConnectivityResult.none && mounted) {
          _autoSwitchToAudioOnly();
        }
      });
    } else if (result == ConnectivityResult.mobile) {
      // Req 10.2 — prompt after 10 s on mobile-only
      _sustainedTimer = Timer(const Duration(seconds: 10), () {
        if (_lastConnectivity == ConnectivityResult.mobile &&
            mounted &&
            !_showingAudioDialog) {
          _showAudioOnlyPrompt();
        }
      });
    } else if (result == ConnectivityResult.wifi) {
      // Req 10.8 — offer video restore if currently in audio_only mode after 10 s
      if (consultation.mode == 'audio_only') {
        _sustainedTimer = Timer(const Duration(seconds: 10), () {
          if (mounted) _showVideoRestorePrompt();
        });
      }
    }
  }

  // ── Audio-only prompt (non-dismissible from outside) ────────────────────────

  void _showAudioOnlyPrompt() {
    _showingAudioDialog = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Low Bandwidth Detected'),
        content: const Text(
          'Your connection quality is low. Switch to audio-only mode to keep the consultation going?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showingAudioDialog = false;
              // Req 10.7 — user dismisses: stay in video, no Firestore write
            },
            child: const Text('Continue in Video'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showingAudioDialog = false;
              await _switchToAudioOnly();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Switch to Audio Only'),
          ),
        ],
      ),
    );
  }

  // ── Video restore prompt ─────────────────────────────────────────────────────

  void _showVideoRestorePrompt() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Connection Restored'),
        content: const Text(
          'Your connection has improved. Would you like to re-enable video?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay Audio Only'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _switchToVideo();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enable Video'),
          ),
        ],
      ),
    );
  }

  // ── Service calls ────────────────────────────────────────────────────────────

  Future<void> _autoSwitchToAudioOnly() async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;
    final consultation = ref.read(consultationStreamProvider(widget.consultationId)).value;
    if (consultation == null) return;
    try {
      await ref
          .read(consultationServiceProvider)
          .switchToAudioOnly(consultation, authState.user.fullName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Switched to audio-only mode due to poor connectivity.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('[ConsultationScreen] Auto audio-only switch failed: $e');
    }
  }

  Future<void> _switchToAudioOnly() async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;
    final consultation = ref.read(consultationStreamProvider(widget.consultationId)).value;
    if (consultation == null) return;
    try {
      await ref
          .read(consultationServiceProvider)
          .switchToAudioOnly(consultation, authState.user.fullName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not switch to audio-only. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _switchToVideo() async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;
    final consultation = ref.read(consultationStreamProvider(widget.consultationId)).value;
    if (consultation == null) return;
    try {
      await ref
          .read(consultationServiceProvider)
          .switchToVideo(consultation, authState.user.fullName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not re-enable video. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _joinConsultation(ConsultationModel consultation) async {
    setState(() => _joining = true);
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) {
      setState(() => _joining = false);
      return;
    }
    try {
      await ref
          .read(consultationServiceProvider)
          .joinRoom(consultation, authState.user.fullName);

      _noAnswerTimer?.cancel();
      if (!_isAnswered) {
        _noAnswerTimer = Timer(const Duration(minutes: 5), () async {
          if (!_isAnswered && mounted) {
            await _handleCallTimeout(consultation);
          }
        });
      }
    } on InvalidRoomException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Consultation room is not available yet.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Unable to join the consultation. Please check your connection.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _endConsultation(ConsultationModel consultation) async {
    setState(() => _ending = true);
    try {
      await ref
          .read(consultationServiceProvider)
          .endConsultation(consultation);
      if (mounted) context.go('/consultations');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not save session data. You\'ve been returned to your consultations.'),
          ),
        );
        context.go('/consultations');
      }
    } finally {
      if (mounted) setState(() => _ending = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final consultationAsync =
        ref.watch(consultationStreamProvider(widget.consultationId));
    final authState = ref.watch(authNotifierProvider);
    final isDoctor = authState is AuthAuthenticated &&
        authState.user.role == UserRole.doctor;

    consultationAsync.whenData((consultation) {
      if (consultation != null) {
        final otherUserId = isDoctor ? consultation.patientId : consultation.doctorId;
        final otherUserAsync = ref.watch(userProfileProvider(otherUserId));
        otherUserAsync.whenData((otherUser) {
          if (otherUser != null && otherUser.inCall == true) {
            _isAnswered = true;
            _noAnswerTimer?.cancel();
          }
        });
      }
    });

    // Auto-navigate when consultation completes
    ref.listen(consultationStreamProvider(widget.consultationId),
        (_, next) {
      final c = next.value;

      if (c != null &&
          (c.status == 'completed' || c.status == 'cancelled') &&
          mounted) {
        if (_timedOut) {
          return;
        }
        if (c.status == 'completed' && !isDoctor) {
          _showPrescriptionWaitingDialog(context);
        } else {
          context.go('/consultations');
        }
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.neutralBackground,
      appBar: AppBar(
        title: const Text('Consultation Room'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/consultations'),
        ),
      ),
      body: consultationAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppTheme.errorColor),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load consultation.',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutralDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  err.toString(),
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.neutralMedium),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (consultation) {
          if (consultation == null) {
            return const Center(
              child: Text(
                'Consultation not found.',
                style: TextStyle(color: AppTheme.neutralMedium),
              ),
            );
          }
          return _ConsultationBody(
            consultation: consultation,
            isDoctor: isDoctor,
            joining: _joining,
            ending: _ending,
            onJoin: () => _joinConsultation(consultation),
            onEnd: () => _endConsultation(consultation),
          );
        },
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ConsultationBody extends StatelessWidget {
  final ConsultationModel consultation;
  final bool isDoctor;
  final bool joining;
  final bool ending;
  final VoidCallback onJoin;
  final VoidCallback onEnd;

  const _ConsultationBody({
    required this.consultation,
    required this.isDoctor,
    required this.joining,
    required this.ending,
    required this.onJoin,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final canJoin = consultation.status == 'scheduled' ||
        consultation.status == 'active';
    final canEnd = isDoctor && consultation.status == 'active';
    final modeLabel =
        consultation.mode == 'audio_only' ? 'Audio Only' : 'Video';
    final statusLabel = consultation.status[0].toUpperCase() +
        consultation.status.substring(1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Consultation Room',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutralDark,
                      ),
                    ),
                    _StatusBadge(status: consultation.status),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.videocam_outlined,
                  label: 'Mode',
                  value: modeLabel,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  label: 'Duration',
                  value: consultation.startedAt != null
                      ? '${consultation.duration} min'
                      : 'Not started',
                ),
                if (consultation.startedAt != null) ...[
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.play_circle_outline_rounded,
                    label: 'Started',
                    value: _formatTime(consultation.startedAt!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Join button
          if (canJoin)
            ElevatedButton.icon(
              onPressed: joining ? null : onJoin,
              icon: joining
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.video_call_rounded, size: 20),
              label: Text(joining ? 'Joining...' : 'Join Consultation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

          if (canJoin && canEnd) const SizedBox(height: 12),

          // End button (doctor only, active only)
          if (canEnd)
            ElevatedButton.icon(
              onPressed: ending ? null : onEnd,
              icon: ending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.call_end_rounded, size: 20),
              label: Text(ending ? 'Ending...' : 'End Consultation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

          // Completed/cancelled message
          if (!canJoin && !canEnd)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.neutralSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: AppTheme.successColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'This consultation is $statusLabel.',
                    style: const TextStyle(
                      color: AppTheme.neutralMedium,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status.toLowerCase()) {
      'active' => (AppTheme.statusApproved, AppTheme.statusApprovedText),
      'completed' => (AppTheme.statusCompleted, AppTheme.statusCompletedText),
      'cancelled' => (AppTheme.statusRejected, AppTheme.statusRejectedText),
      _ => (AppTheme.statusPending, AppTheme.statusPendingText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            color: fg, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.neutralLight),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
              fontSize: 12, color: AppTheme.neutralMedium),
        ),
        Text(
          value,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutralDark),
        ),
      ],
    );
  }
}
