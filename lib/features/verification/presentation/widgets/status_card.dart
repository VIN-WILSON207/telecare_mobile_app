import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final String status;
  final DateTime date;
  final String? rejectionReason;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const StatusCard({
    super.key,
    required this.status,
    required this.date,
    this.rejectionReason,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine colors and icons based on status
    Color cardBgColor;
    Color borderStrokeColor;
    Color contentColor;
    IconData icon;
    String statusTitle;
    String statusSubtitle;

    switch (status.toLowerCase()) {
      case 'approved':
        cardBgColor = const Color(0xFFE8F5E9); // Light green
        borderStrokeColor = const Color(0xFFA5D6A7);
        contentColor = const Color(0xFF2E7D32); // Dark green
        icon = Icons.verified_user_rounded;
        statusTitle = 'Credentials Verified';
        statusSubtitle = 'You have full access to all doctor features, including appointments and consultations.';
        break;
      case 'rejected':
        cardBgColor = const Color(0xFFFFEBEE); // Light red
        borderStrokeColor = const Color(0xFFFFCDD2);
        contentColor = const Color(0xFFC62828); // Dark red
        icon = Icons.gpp_bad_rounded;
        statusTitle = 'Verification Rejected';
        statusSubtitle = rejectionReason ?? 'Your documents did not meet our verification standards. Please review the reasons below and resubmit.';
        break;
      case 'pending':
      default:
        cardBgColor = const Color(0xFFFFF8E1); // Light amber
        borderStrokeColor = const Color(0xFFFFE082);
        contentColor = const Color(0xFFF57C00); // Dark amber/orange
        icon = Icons.pending_actions_rounded;
        statusTitle = 'Verification Pending';
        statusSubtitle = 'Our administrative team is currently reviewing your credentials. This process usually takes 24-48 hours.';
        break;
    }

    final formattedDate = '${date.day}/${date.month}/${date.year}';

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderStrokeColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderStrokeColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: contentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: contentColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: contentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submitted on $formattedDate',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: contentColor.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: borderStrokeColor.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            statusSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: contentColor.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          if (status.toLowerCase() == 'rejected' && onActionPressed != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onActionPressed,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel ?? 'Resubmit Credentials'),
              style: ElevatedButton.styleFrom(
                backgroundColor: contentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
