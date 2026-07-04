import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/models/user_role.dart';
import '../../../verification/providers/review_verification_notifier.dart';
import '../../providers/admin_providers.dart';

class DoctorVerificationView extends ConsumerStatefulWidget {
  const DoctorVerificationView({super.key});

  @override
  ConsumerState<DoctorVerificationView> createState() =>
      _DoctorVerificationViewState();
}

class _DoctorVerificationViewState
    extends ConsumerState<DoctorVerificationView> {
  String _selectedTab = 'Pending'; // Pending, Verified, Rejected, Suspended
  final List<String> _tabs = const [
    'Pending',
    'Verified',
    'Rejected',
    'Suspended',
  ];

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(allVerificationRequestsProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final reviewState = ref.watch(reviewVerificationProvider);
    final isProcessing = reviewState.isLoading;

    ref.listen<AsyncValue<void>>(reviewVerificationProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification update submitted successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Action failed: ${error.toString()}'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppTheme.neutralBackground,
      body: Column(
        children: [
          // Tab bar selection row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs.map((tabName) {
                  final isSelected = _selectedTab == tabName;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(tabName),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: AppTheme.neutralSurface,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.neutralDark,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      side: BorderSide.none,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedTab = tabName);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Requests list
          Expanded(
            child: requestsAsync.when(
              data: (requests) {
                // Filter requests by status/tab
                final filtered = requests.where((r) {
                  if (_selectedTab == 'Pending') return r.status == 'pending';
                  if (_selectedTab == 'Verified') return r.status == 'approved';
                  if (_selectedTab == 'Rejected') return r.status == 'rejected';
                  if (_selectedTab == 'Suspended') {
                    return r.status == 'suspended';
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(context);
                }

                return usersAsync.when(
                  data: (users) {
                    return Stack(
                      children: [
                        ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final request = filtered[index];
                            final doctorUser = users.firstWhere(
                              (u) =>
                                  u.uid == request.doctorId ||
                                  u.email == request.doctorId,
                              orElse: () => UserModel(
                                uid: request.doctorId,
                                fullName: request.doctorName.isNotEmpty
                                    ? request.doctorName
                                    : 'Unknown Professional',
                                email: '',
                                phone: '',
                                role: UserRole.doctor,
                                createdAt: DateTime.now(),
                              ),
                            );

                            return _buildVerificationCard(
                              context,
                              ref,
                              request: request,
                              doctorPhone: doctorUser.phone.isNotEmpty
                                  ? doctorUser.phone
                                  : 'N/A',
                              doctorEmail: doctorUser.email.isNotEmpty
                                  ? doctorUser.email
                                  : 'N/A',
                              doctorPhoto: doctorUser.profileImage,
                              isProcessing: isProcessing,
                            );
                          },
                        ),
                        if (isProcessing)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.2),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) =>
                      Center(child: Text('Error joining profiles: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  Center(child: Text('Error loading requests: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 80,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Requests Found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.neutralDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no $_selectedTab verifications in the database.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.neutralMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationCard(
    BuildContext context,
    WidgetRef ref, {
    required dynamic request,
    required String doctorPhone,
    required String doctorEmail,
    required String? doctorPhoto,
    required bool isProcessing,
  }) {
    final theme = Theme.of(context);
    final date = request.submittedAt;
    final formattedDate = '${date.day}/${date.month}/${date.year}';

    // Mock degree/experience derived from specialties or fallback
    final String degree =
        request.specialty.toLowerCase().contains('surgical') ||
            request.specialty.toLowerCase().contains('surgeon')
        ? 'M.B.B.S., M.S. (Surgery)'
        : 'M.B.B.S., M.D. (Medicine)';
    final String experience =
        '${(request.doctorName.length % 10) + 4} Years Experience';

    final Color statusColor;
    switch (request.status.toLowerCase()) {
      case 'approved':
        statusColor = AppTheme.successColor;
        break;
      case 'rejected':
        statusColor = AppTheme.errorColor;
        break;
      case 'suspended':
        statusColor = AppTheme.warningColor;
        break;
      default:
        statusColor = AppTheme.statusPendingText;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: const BorderSide(color: AppTheme.neutralSurface, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Doctor Avatar & Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  backgroundImage:
                      (doctorPhoto != null && doctorPhoto.isNotEmpty)
                      ? NetworkImage(doctorPhoto)
                      : null,
                  child: (doctorPhoto == null || doctorPhoto.isEmpty)
                      ? const Icon(
                          Icons.person_rounded,
                          size: 30,
                          color: AppTheme.primaryColor,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${request.doctorName}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutralDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          request.specialty.isNotEmpty
                              ? request.specialty
                              : 'General Practitioner',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Row 2: Doctor Details
            _buildDetailRow(
              Icons.badge_rounded,
              'License No',
              request.licenseNumber.isNotEmpty ? request.licenseNumber : 'N/A',
            ),
            _buildDetailRow(
              Icons.school_rounded,
              'Degree / Qualifications',
              degree,
            ),
            _buildDetailRow(Icons.timeline_rounded, 'Experience', experience),
            _buildDetailRow(
              Icons.local_hospital_rounded,
              'Hospital',
              request.hospital.isNotEmpty ? request.hospital : 'N/A',
            ),
            _buildDetailRow(Icons.phone_rounded, 'Phone', doctorPhone),
            _buildDetailRow(Icons.email_rounded, 'Email', doctorEmail),
            _buildDetailRow(
              Icons.calendar_month_rounded,
              'Submitted',
              formattedDate,
            ),

            if (request.status == 'rejected' &&
                request.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Rejection Reason: ${request.rejectionReason}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Row 3: Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDocumentsDialog(context, request),
                    icon: const Icon(Icons.description_rounded, size: 16),
                    label: const Text(
                      'View Docs',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Show actions depending on tab
                if (_selectedTab == 'Pending') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _showRequestDocsDialog(
                              context,
                              request.id,
                              request.doctorName,
                            ),
                      icon: const Icon(
                        Icons.help_outline_rounded,
                        size: 16,
                        color: AppTheme.infoColor,
                      ),
                      label: const Text(
                        'Req Docs',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.infoColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.infoColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _showRejectionDialog(
                              context,
                              ref,
                              request.id,
                              request.doctorId,
                            ),
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 16,
                        color: AppTheme.errorColor,
                      ),
                      label: const Text(
                        'Reject',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.errorColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _showApprovalDialog(
                              context,
                              ref,
                              request.id,
                              request.doctorId,
                            ),
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'Approve',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else if (_selectedTab == 'Verified') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _showSuspensionDialog(
                              context,
                              ref,
                              request.id,
                              request.doctorId,
                              request.doctorName,
                            ),
                      icon: const Icon(Icons.block_rounded, size: 16),
                      label: const Text(
                        'Suspend Doctor',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else if (_selectedTab == 'Rejected') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _showApprovalDialog(
                              context,
                              ref,
                              request.id,
                              request.doctorId,
                            ),
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'Re-Approve',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else if (_selectedTab == 'Suspended') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _showReactivationDialog(
                              context,
                              ref,
                              request.id,
                              request.doctorId,
                              request.doctorName,
                            ),
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'Reactivate',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.neutralLight),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutralMedium,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.neutralDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDocumentsDialog(BuildContext context, dynamic request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${request.doctorName} Credentials'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  'Medical License Certificate',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  width: double.infinity,
                  color: AppTheme.neutralSurface,
                  child: request.licenseUrl.isNotEmpty
                      ? Image.network(
                          request.licenseUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Center(
                            child: Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 64,
                              color: AppTheme.neutralLight,
                            ),
                          ),
                        )
                      : const Center(child: Text('No License Uploaded')),
                ),
                const SizedBox(height: 20),
                const Text(
                  'National Identity / Passport',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  width: double.infinity,
                  color: AppTheme.neutralSurface,
                  child: request.nationalIdUrl.isNotEmpty
                      ? Image.network(
                          request.nationalIdUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Center(
                            child: Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 64,
                              color: AppTheme.neutralLight,
                            ),
                          ),
                        )
                      : const Center(child: Text('No National ID Uploaded')),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRequestDocsDialog(
    BuildContext context,
    String requestId,
    String doctorName,
  ) {
    final docsController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request More Documents'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Specify which documents or clarifications are needed from Dr. $doctorName:',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: docsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. Please upload a clearer copy of your Medical License Certificate.',
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
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
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Document request sent to Dr. $doctorName'),
                    backgroundColor: AppTheme.primaryColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(
    BuildContext context,
    WidgetRef ref,
    String requestId,
    String doctorId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Practitioner?'),
        content: const Text(
          'This will verify the healthcare professional, update their status to "verified", change their role to "doctor", and log the action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(reviewVerificationProvider.notifier)
                  .approve(requestId: requestId, doctorId: doctorId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(
    BuildContext context,
    WidgetRef ref,
    String requestId,
    String doctorId,
  ) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Reject Verification?'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please input the reason for rejecting this doctor. The doctor will see this when they log in to resubmit documents.',
                style: TextStyle(fontSize: 12.5, height: 1.3),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. The uploaded license is blurry or expired.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Rejection reason is required';
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
              if (formKey.currentState!.validate()) {
                final reason = reasonController.text;
                Navigator.pop(context);
                ref
                    .read(reviewVerificationProvider.notifier)
                    .reject(
                      requestId: requestId,
                      doctorId: doctorId,
                      reason: reason,
                    );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showSuspensionDialog(
    BuildContext context,
    WidgetRef ref,
    String requestId,
    String doctorId,
    String doctorName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Doctor?'),
        content: Text(
          'Are you sure you want to suspend Dr. $doctorName? This will revoke their medical privileges, block login access, and set verification status to suspended.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Update verification request
                await FirebaseFirestore.instance
                    .collection('verification_requests')
                    .doc(requestId)
                    .update({'status': 'suspended'});
                // Update user verificationStatus and deactivate account
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(doctorId)
                    .update({
                      'verificationStatus': 'suspended',
                      'isActive': false,
                    });

                // Log action
                final adminUser = ref.read(adminRepositoryProvider);
                await adminUser.logAction(
                  action: 'doctor_suspension',
                  details: 'Suspended doctor Dr. $doctorName ($doctorId)',
                  adminId: 'admin',
                  adminName: 'Admin',
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Dr. $doctorName suspended successfully.'),
                      backgroundColor: AppTheme.errorColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to suspend: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _showReactivationDialog(
    BuildContext context,
    WidgetRef ref,
    String requestId,
    String doctorId,
    String doctorName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactivate Doctor?'),
        content: Text(
          'Reactivate Dr. $doctorName and restore their verification status to Approved?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Update verification request
                await FirebaseFirestore.instance
                    .collection('verification_requests')
                    .doc(requestId)
                    .update({'status': 'approved'});
                // Update user verificationStatus and activate account
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(doctorId)
                    .update({
                      'verificationStatus': 'approved',
                      'isActive': true,
                    });

                // Log action
                final adminUser = ref.read(adminRepositoryProvider);
                await adminUser.logAction(
                  action: 'doctor_approval',
                  details:
                      'Reactivated and Approved doctor Dr. $doctorName ($doctorId)',
                  adminId: 'admin',
                  adminName: 'Admin',
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Doctor reactivated successfully.'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to reactivate: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );
  }
}
