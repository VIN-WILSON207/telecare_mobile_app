import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/models/user_role.dart';
import '../../data/models/consultation_model.dart';
import '../../providers/consultation_providers.dart';

class ConsultationHistoryScreen extends ConsumerWidget {
  final UserModel user;

  const ConsultationHistoryScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultationsAsync = ref.watch(userConsultationsProvider(user.uid));
    final isDoctor = user.role == UserRole.doctor;
    final title = isDoctor ? 'Consultation Records' : 'Previous Consultations';

    return consultationsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      error: (err, _) => _ErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(userConsultationsProvider(user.uid)),
      ),
      data: (consultations) {
        if (consultations.isEmpty) {
          return _EmptyState(title: title);
        }
        return _ConsultationList(
          consultations: consultations,
          isDoctor: isDoctor,
          title: title,
        );
      },
    );
  }
}

// ── Consultation List ─────────────────────────────────────────────────────────

class _ConsultationList extends StatelessWidget {
  final List<ConsultationModel> consultations;
  final bool isDoctor;
  final String title;

  const _ConsultationList({
    required this.consultations,
    required this.isDoctor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: consultations.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ConsultationCard(
          consultation: consultations[index],
          isDoctor: isDoctor,
        ),
      ),
    );
  }
}

// ── Consultation Card ─────────────────────────────────────────────────────────

class _ConsultationCard extends StatelessWidget {
  final ConsultationModel consultation;
  final bool isDoctor;

  const _ConsultationCard({
    required this.consultation,
    required this.isDoctor,
  });

  @override
  Widget build(BuildContext context) {
    final otherParty = isDoctor
        ? 'Patient: ${consultation.patientId}'
        : 'Dr. ${consultation.doctorId}';

    final dateStr = DateFormat('d MMM yyyy').format(consultation.createdAt);
    final durationStr = '${consultation.duration} min';
    final statusInfo = _statusInfo(consultation.status);
    final modeInfo = _modeInfo(consultation.mode);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: avatar + name + status badge
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.video_call_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  otherParty,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.neutralDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusInfo.$2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusInfo.$1,
                  style: TextStyle(
                    color: statusInfo.$3,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Date row
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: AppTheme.neutralLight,
              ),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.neutralMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Duration + mode row
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 12,
                color: AppTheme.neutralLight,
              ),
              const SizedBox(width: 6),
              Text(
                durationStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.neutralMedium,
                ),
              ),
              const SizedBox(width: 12),
              // Mode chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: modeInfo.$2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  modeInfo.$1,
                  style: TextStyle(
                    color: modeInfo.$3,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Returns (label, backgroundColor, textColor) for a consultation status.
  static (String, Color, Color) _statusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return ('ACTIVE', AppTheme.statusApproved, AppTheme.statusApprovedText);
      case 'completed':
        return (
          'COMPLETED',
          AppTheme.statusCompleted,
          AppTheme.statusCompletedText,
        );
      case 'cancelled':
        return (
          'CANCELLED',
          AppTheme.statusRejected,
          AppTheme.statusRejectedText,
        );
      case 'scheduled':
      default:
        return (
          'SCHEDULED',
          AppTheme.statusPending,
          AppTheme.statusPendingText,
        );
    }
  }

  /// Returns (label, backgroundColor, textColor) for a consultation mode.
  static (String, Color, Color) _modeInfo(String mode) {
    if (mode == 'audio_only') {
      return (
        'Audio Only',
        const Color(0xFFFEF3C7),
        const Color(0xFFD97706),
      );
    }
    return (
      'Video',
      AppTheme.primarySurface,
      AppTheme.primaryColor,
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String title;

  const _EmptyState({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 56,
              color: AppTheme.neutralLight,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.neutralDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No consultations found.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neutralMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to load consultations.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.neutralDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.neutralMedium,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(140, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
