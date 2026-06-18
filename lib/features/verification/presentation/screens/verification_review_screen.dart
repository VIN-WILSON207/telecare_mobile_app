import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telecare_mobile_app/features/verification/providers/review_verification_notifier.dart';
import 'package:telecare_mobile_app/features/verification/providers/verification_providers.dart';
import 'package:telecare_mobile_app/features/verification/presentation/widgets/document_viewer.dart';

class VerificationReviewScreen extends ConsumerStatefulWidget {
  final String requestId;

  const VerificationReviewScreen({
    super.key,
    required this.requestId,
  });

  @override
  ConsumerState<VerificationReviewScreen> createState() =>
      _VerificationReviewScreenState();
}

class _VerificationReviewScreenState extends ConsumerState<VerificationReviewScreen> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requestAsync = ref.watch(verificationRequestByIdProvider(widget.requestId));
    final reviewState = ref.watch(reviewVerificationProvider);
    final isProcessing = reviewState.isLoading;

    // Listen to review action states (approve / reject)
    ref.listen<AsyncValue<void>>(reviewVerificationProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification review submitted successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Go back to the pending list
          context.pop();
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Review failed: ${error.toString()}'),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Credentials'),
        leading: isProcessing ? const SizedBox.shrink() : null, // disable back button when processing
      ),
      body: SafeArea(
        child: requestAsync.when(
          data: (request) {
            if (request == null) {
              return Center(
                child: Text(
                  'Verification request not found.',
                  style: theme.textTheme.titleMedium,
                ),
              );
            }

            final date = request.submittedAt;
            final formattedDate = '${date.day}/${date.month}/${date.year}';

            return Stack(
              children: [
                // Scrollable main content
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Doctor info banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dr. ${request.doctorName}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Doctor ID: ${request.doctorId}',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Submitted on $formattedDate',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Document Viewers
                        Text(
                          'Credentials Files',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        DocumentViewer(
                          title: 'National Identity Document (ID)',
                          documentUrl: request.nationalIdUrl,
                        ),
                        const SizedBox(height: 20),

                        DocumentViewer(
                          title: 'Medical Practice License',
                          documentUrl: request.licenseUrl,
                        ),
                        const SizedBox(height: 120), // spacer for bottom action bar
                      ],
                    ),
                  ),
                ),

                // Absolute positioned action bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Reject button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : () => _showRejectionDialog(
                                      requestId: request.id,
                                      doctorId: request.doctorId,
                                    ),
                            icon: const Icon(Icons.cancel_outlined, color: Color(0xFFC62828)),
                            label: const Text(
                              'Reject',
                              style: TextStyle(color: Color(0xFFC62828)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFC62828)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Approve button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : () => _handleApprove(
                                      requestId: request.id,
                                      doctorId: request.doctorId,
                                    ),
                            icon: const Icon(Icons.check_circle_outline_rounded),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Full-screen loading overlay
                if (isProcessing)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: theme.colorScheme.error,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load verification request details.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(verificationRequestByIdProvider(widget.requestId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------

  void _handleApprove({required String requestId, required String doctorId}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Credentials?'),
        content: const Text(
          'Approving this request will immediately verify the healthcare professional and grant them access to telemedicine features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(reviewVerificationProvider.notifier).approve(
                    requestId: requestId,
                    doctorId: doctorId,
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog({required String requestId, required String doctorId}) {
    _reasonController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Reject Verification?'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please specify the reason for rejecting Dr. Credentials. The doctor will see this feedback when resubmitting.',
                style: TextStyle(fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'e.g. The medical license has expired or the uploaded photo of the ID is blurry and illegible.',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'A rejection reason is required.';
                  }
                  if (value.trim().length < 10) {
                    return 'Please provide a more detailed reason (min 10 characters).';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final reason = _reasonController.text;
                Navigator.pop(context);
                ref.read(reviewVerificationProvider.notifier).reject(
                      requestId: requestId,
                      doctorId: doctorId,
                      reason: reason,
                    );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            child: const Text('Reject Verification'),
          ),
        ],
      ),
    );
  }
}
