import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../auth/providers/auth_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/models/user_role.dart';
import '../../providers/admin_providers.dart';

class UserManagementView extends ConsumerStatefulWidget {
  const UserManagementView({super.key});

  @override
  ConsumerState<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends ConsumerState<UserManagementView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Patients, Doctors, Admins
  String _doctorSubFilter = 'All'; // All, Verified, Pending, Rejected, Suspended

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    final adminUser = ref.watch(authNotifierProvider);
    final adminUid = adminUser is AuthAuthenticated ? adminUser.user.uid : 'admin';
    final adminName = adminUser is AuthAuthenticated ? adminUser.user.fullName : 'Admin';

    return usersAsync.when(
      data: (users) {
        // Apply Filters
        var filteredUsers = users.where((u) {
          final query = _searchQuery.toLowerCase();
          final matchesSearch = u.fullName.toLowerCase().contains(query) ||
              u.email.toLowerCase().contains(query) ||
              u.phone.contains(query);

          if (!matchesSearch) return false;

          switch (_selectedFilter) {
            case 'Patients':
              return u.role == UserRole.patient;
            case 'Admins':
              return u.role == UserRole.admin;
            case 'Doctors':
              if (!u.role.isHealthcareProfessional) {
                return false;
              }
              switch (_doctorSubFilter) {
                case 'Verified':
                  return u.verificationStatus == 'approved';
                case 'Pending':
                  return u.verificationStatus == 'pending';
                case 'Rejected':
                  return u.verificationStatus == 'rejected';
                case 'Suspended':
                  return u.verificationStatus == 'suspended';
                case 'All':
                default:
                  return true;
              }
            case 'All':
            default:
              return true;
          }
        }).toList();

        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SearchField(
                controller: _searchController,
                hintText: 'Search by name, email, or phone...',
                onChanged: (val) => setState(() => _searchQuery = val),
                showClear: _searchQuery.isNotEmpty,
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.neutralMedium),
                backgroundColor: AppTheme.cardWhite,
                borderColor: const Color(0xFFE2E8F0),
                hintColor: AppTheme.neutralLight,
                textColor: Colors.black87,
              ),
            ),

            // Primary Filters scroll list
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: ['All', 'Patients', 'Doctors', 'Admins'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: AppTheme.neutralSurface,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.neutralDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide.none,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilter = filter;
                            _doctorSubFilter = 'All'; // Reset sub-filter
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // Nested Doctor Sub-Filters
            if (_selectedFilter == 'Doctors') ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: ['All', 'Verified', 'Pending', 'Rejected', 'Suspended'].map((subFilter) {
                    final isSelected = _doctorSubFilter == subFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(subFilter),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: AppTheme.neutralSurface,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.neutralDark,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        side: BorderSide.none,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _doctorSubFilter = subFilter);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 4),

            // Users List
            Expanded(
              child: filteredUsers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return _buildUserCard(
                          context,
                          user: user,
                          adminUid: adminUid,
                          adminName: adminName,
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading users: $e')),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 64, color: AppTheme.neutralLight),
            SizedBox(height: 16),
            Text(
              'No matching users found.',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neutralMedium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context, {
    required UserModel user,
    required String adminUid,
    required String adminName,
  }) {
    final theme = Theme.of(context);
    final isDoctor = user.role.isHealthcareProfessional;
    final isVerifiedDoctor = isDoctor && user.verificationStatus == 'approved';
    final isSuspendedDoctor = isDoctor && user.verificationStatus == 'suspended';

    // Mock last login time derived from uid/hash
    final String lastLogin = '${(user.uid.hashCode % 12) + 1} hours ago';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: const BorderSide(color: AppTheme.neutralSurface, width: 1.2),
      ),
      child: InkWell(
        onTap: () => _showUserProfileDialog(context, user),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
                    backgroundImage: (user.profileImage != null && user.profileImage!.isNotEmpty)
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child: (user.profileImage == null || user.profileImage!.isEmpty)
                        ? Icon(
                            user.role.isHealthcareProfessional
                                ? Icons.medical_services_rounded
                                : user.role == UserRole.admin
                                    ? Icons.admin_panel_settings_rounded
                                    : Icons.person_rounded,
                            color: _getRoleColor(user.role),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.fullName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.neutralDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (isVerifiedDoctor)
                              const Icon(Icons.verified_rounded, color: AppTheme.successColor, size: 16),
                            if (isSuspendedDoctor)
                              const Icon(Icons.block_rounded, color: AppTheme.warningColor, size: 16),
                          ],
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(fontSize: 12.5, color: AppTheme.neutralMedium),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user.role.value.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getRoleColor(user.role),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isSuspendedDoctor
                            ? 'SUSPENDED'
                            : (user.isActive ? 'ACTIVE' : 'DEACTIVATED'),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isSuspendedDoctor
                              ? AppTheme.warningColor
                              : (user.isActive ? AppTheme.successColor : AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded, size: 14, color: AppTheme.neutralLight),
                      const SizedBox(width: 4),
                      Text(
                        'Last Login: $lastLogin',
                        style: const TextStyle(fontSize: 11, color: AppTheme.neutralMedium),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _showUserProfileDialog(context, user),
                        icon: const Icon(Icons.visibility_rounded, size: 14),
                        label: const Text('View', style: TextStyle(fontSize: 11.5)),
                      ),
                      if (user.role != UserRole.admin) ...[
                        if (isDoctor)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _toggleDoctorSuspension(
                              context,
                              user: user,
                              adminUid: adminUid,
                              adminName: adminName,
                            ),
                            icon: Icon(
                              isSuspendedDoctor ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                              size: 14,
                              color: isSuspendedDoctor ? AppTheme.successColor : AppTheme.warningColor,
                            ),
                            label: Text(
                              isSuspendedDoctor ? 'Unsuspend' : 'Suspend',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isSuspendedDoctor ? AppTheme.successColor : AppTheme.warningColor,
                              ),
                            ),
                          )
                        else
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _toggleUserActiveStatus(
                              context,
                              user: user,
                              adminUid: adminUid,
                              adminName: adminName,
                            ),
                            icon: Icon(
                              user.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                              size: 14,
                              color: user.isActive ? AppTheme.errorColor : AppTheme.successColor,
                            ),
                            label: Text(
                              user.isActive ? 'Deactivate' : 'Activate',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: user.isActive ? AppTheme.errorColor : AppTheme.successColor,
                              ),
                            ),
                          ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _confirmDeleteUser(
                            context,
                            user: user,
                            adminUid: adminUid,
                            adminName: adminName,
                          ),
                          icon: const Icon(Icons.delete_outline_rounded, size: 14, color: AppTheme.errorColor),
                          label: const Text(
                            'Delete',
                            style: TextStyle(fontSize: 11.5, color: AppTheme.errorColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple.shade700;
      case UserRole.doctor:
        return AppTheme.primaryColor;
      case UserRole.patient:
        return AppTheme.infoColor;
      case UserRole.nurse:
        return Colors.teal;
      case UserRole.labTechnician:
        return Colors.orange.shade800;
      case UserRole.pharmacist:
        return Colors.blue.shade700;
      case UserRole.physiotherapist:
        return Colors.green.shade700;
    }
  }

  void _showUserProfileDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: (user.profileImage != null && user.profileImage!.isNotEmpty)
                  ? NetworkImage(user.profileImage!)
                  : null,
              child: (user.profileImage == null || user.profileImage!.isEmpty)
                  ? const Icon(Icons.person_rounded)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileDetail('Role', user.role.label.toUpperCase()),
            _buildProfileDetail('Email', user.email),
            _buildProfileDetail('Phone', user.phone.isNotEmpty ? user.phone : 'N/A'),
            _buildProfileDetail('Status', user.verificationStatus == 'suspended' ? 'Suspended' : (user.isActive ? 'Active' : 'Deactivated')),
            if (user.role.isHealthcareProfessional) ...[
              _buildProfileDetail('Verification', user.verificationStatus.toUpperCase()),
              _buildProfileDetail('Specialty', user.specialty ?? 'N/A'),
              _buildProfileDetail('License Number', user.licenseNumber ?? 'N/A'),
              _buildProfileDetail('Hospital', user.hospital ?? 'N/A'),
            ],
            _buildProfileDetail('Registered At', '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
          ],
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

  Widget _buildProfileDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppTheme.neutralDark, fontSize: 13.5, fontFamily: 'Poppins'),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neutralMedium)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  void _toggleDoctorSuspension(
    BuildContext context, {
    required UserModel user,
    required String adminUid,
    required String adminName,
  }) {
    final bool isSuspended = user.verificationStatus == 'suspended';
    final roleLabel = user.role.label;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSuspended ? 'Unsuspend $roleLabel?' : 'Suspend $roleLabel?'),
        content: Text(
          isSuspended
              ? 'Are you sure you want to restore access and verify status for $roleLabel ${user.fullName}?'
              : 'Are you sure you want to suspend $roleLabel ${user.fullName}? They will be blocked from logging in immediately and their verification status set to suspended.',
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
                // Update in Firestore collection
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                  'verificationStatus': isSuspended ? 'approved' : 'suspended',
                  'isActive': isSuspended ? true : false,
                });

                // Update verification requests as well
                final requestsQuery = await FirebaseFirestore.instance
                    .collection('verification_requests')
                    .where('doctorId', isEqualTo: user.uid)
                    .orderBy('submittedAt', descending: true)
                    .limit(1)
                    .get();
                if (requestsQuery.docs.isNotEmpty) {
                  await requestsQuery.docs.first.reference.update({
                    'status': isSuspended ? 'approved' : 'suspended',
                  });
                }

                // Log audit action
                await ref.read(adminRepositoryProvider).logAction(
                      action: 'profile_update',
                      details: '${isSuspended ? "Unsuspended" : "Suspended"} $roleLabel ${user.fullName} (${user.uid})',
                      adminId: adminUid,
                      adminName: adminName,
                    );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$roleLabel ${user.fullName} successfully ${isSuspended ? "unsuspended" : "suspended"}.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update status: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuspended ? AppTheme.successColor : AppTheme.warningColor,
            ),
            child: Text(isSuspended ? 'Unsuspend' : 'Suspend'),
          ),
        ],
      ),
    );
  }

  void _toggleUserActiveStatus(
    BuildContext context, {
    required UserModel user,
    required String adminUid,
    required String adminName,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isActive ? 'Deactivate Account?' : 'Activate Account?'),
        content: Text(
          user.isActive
              ? 'Are you sure you want to deactivate ${user.fullName}? They will be blocked from logging in immediately.'
              : 'Are you sure you want to reactivate ${user.fullName}? They will regain platform access immediately.',
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
                await ref.read(adminRepositoryProvider).setUserActiveStatus(
                      uid: user.uid,
                      isActive: !user.isActive,
                      adminId: adminUid,
                      adminName: adminName,
                    );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Account successfully ${user.isActive ? "deactivated" : "reactivated"}.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update status: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? AppTheme.errorColor : AppTheme.successColor,
            ),
            child: Text(user.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(
    BuildContext context, {
    required UserModel user,
    required String adminUid,
    required String adminName,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: Text(
          'Warning: This will permanently delete the user document for ${user.fullName} from Firestore. This action cannot be undone. Are you sure?',
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
                await ref.read(adminRepositoryProvider).deleteUser(
                      uid: user.uid,
                      adminId: adminUid,
                      adminName: adminName,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account permanently deleted from database.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}
