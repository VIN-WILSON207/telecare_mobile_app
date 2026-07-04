import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../appointments/data/models/appointment_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/models/user_role.dart';
import '../../providers/admin_providers.dart';

class AppointmentManagementView extends ConsumerStatefulWidget {
  const AppointmentManagementView({super.key});

  @override
  ConsumerState<AppointmentManagementView> createState() => _AppointmentManagementViewState();
}

class _AppointmentManagementViewState extends ConsumerState<AppointmentManagementView> {
  final _patientSearchController = TextEditingController();
  final _doctorSearchController = TextEditingController();
  String _patientSearch = '';
  String _doctorSearch = '';
  String _selectedStatus = 'All'; // All, Today's, Completed, Cancelled, Missed, Upcoming, Emergency
  String _selectedSpecialty = 'All';
  DateTime? _selectedDate;

  final List<String> _statuses = const [
    'All',
    "Today's",
    'Completed',
    'Cancelled',
    'Missed',
    'Upcoming',
    'Emergency'
  ];

  @override
  void dispose() {
    _patientSearchController.dispose();
    _doctorSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(allAppointmentsProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final today = DateTime.now();

    return appointmentsAsync.when(
      data: (appointments) {
        return usersAsync.when(
          data: (users) {
            // Get all unique specialties
            final specialties = ['All', ...users
                .where((u) => u.role == UserRole.doctor && u.specialty != null && u.specialty!.isNotEmpty)
                .map((u) => u.specialty!)
                .toSet()];

            // Calculate Summary Stats
            final totalCount = appointments.length;
            
            final todayCount = appointments.where((a) {
              return a.appointmentDate.year == today.year &&
                  a.appointmentDate.month == today.month &&
                  a.appointmentDate.day == today.day;
            }).length;

            final completedCount = appointments.where((a) => a.status.toLowerCase() == 'completed').length;

            final emergencyCount = appointments.where((a) {
              final r = a.reason.toLowerCase();
              return r.contains('emergency') || r.contains('critical') || r.contains('urgent') || r.contains('accident');
            }).length;

            // Filter and Search
            var filteredList = appointments.where((a) {
              // Patient Search
              if (_patientSearch.isNotEmpty && !a.patientName.toLowerCase().contains(_patientSearch.toLowerCase())) {
                return false;
              }

              // Doctor Search
              if (_doctorSearch.isNotEmpty && !a.doctorName.toLowerCase().contains(_doctorSearch.toLowerCase())) {
                return false;
              }

              // Specialty Filter
              if (_selectedSpecialty != 'All') {
                final doctor = users.firstWhere(
                  (u) => u.uid == a.doctorId || u.email == a.doctorEmail,
                  orElse: () => UserModel(
                    uid: '',
                    fullName: 'Unknown',
                    email: '',
                    phone: '',
                    role: UserRole.patient,
                    createdAt: DateTime.now(),
                  ),
                );
                final spec = doctor.specialty?.isNotEmpty == true ? doctor.specialty! : 'General Practitioner';
                if (spec.toLowerCase() != _selectedSpecialty.toLowerCase()) {
                  return false;
                }
              }

              // Status filter
              if (_selectedStatus != 'All') {
                if (_selectedStatus == "Today's") {
                  final isToday = a.appointmentDate.year == today.year &&
                      a.appointmentDate.month == today.month &&
                      a.appointmentDate.day == today.day;
                  if (!isToday) return false;
                } else if (_selectedStatus == 'Completed') {
                  if (a.status.toLowerCase() != 'completed') return false;
                } else if (_selectedStatus == 'Cancelled') {
                  if (a.status.toLowerCase() != 'cancelled' && a.status.toLowerCase() != 'rejected') return false;
                } else if (_selectedStatus == 'Missed') {
                  final isPast = a.appointmentDate.isBefore(today);
                  final isNotDone = a.status.toLowerCase() != 'completed' && a.status.toLowerCase() != 'cancelled' && a.status.toLowerCase() != 'rejected';
                  if (!(isPast && isNotDone)) return false;
                } else if (_selectedStatus == 'Upcoming') {
                  final isFuture = a.appointmentDate.isAfter(today);
                  final isNotDone = a.status.toLowerCase() != 'completed' && a.status.toLowerCase() != 'cancelled' && a.status.toLowerCase() != 'rejected';
                  if (!(isFuture && isNotDone)) return false;
                } else if (_selectedStatus == 'Emergency') {
                  final isEmergency = a.reason.toLowerCase().contains('emergency') ||
                      a.reason.toLowerCase().contains('critical') ||
                      a.reason.toLowerCase().contains('urgent') ||
                      a.reason.toLowerCase().contains('accident');
                  if (!isEmergency) return false;
                }
              }

              // Date filter
              if (_selectedDate != null) {
                final matchesDate = a.appointmentDate.year == _selectedDate!.year &&
                    a.appointmentDate.month == _selectedDate!.month &&
                    a.appointmentDate.day == _selectedDate!.day;
                if (!matchesDate) return false;
              }

              return true;
            }).toList();

            return Column(
              children: [
                // ── Summary Stats Bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      _buildSummaryStatCard('Total Bookings', '$totalCount', Icons.calendar_month_rounded, AppTheme.infoColor),
                      const SizedBox(width: 8),
                      _buildSummaryStatCard("Today's", '$todayCount', Icons.today_rounded, AppTheme.accentAlt),
                      const SizedBox(width: 8),
                      _buildSummaryStatCard('Completed', '$completedCount', Icons.check_circle_rounded, AppTheme.successColor),
                      const SizedBox(width: 8),
                      _buildSummaryStatCard('Emergency', '$emergencyCount', Icons.emergency_rounded, AppTheme.errorColor),
                    ],
                  ),
                ),

                // ── Search & Filter Inputs ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SearchField(
                          controller: _patientSearchController,
                          hintText: 'Search Patient...',
                          onChanged: (val) => setState(() => _patientSearch = val),
                          showClear: _patientSearch.isNotEmpty,
                          onClear: () {
                            _patientSearchController.clear();
                            setState(() => _patientSearch = '');
                          },
                          prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.neutralMedium),
                          backgroundColor: AppTheme.cardWhite,
                          borderColor: const Color(0xFFE2E8F0),
                          hintColor: AppTheme.neutralLight,
                          textColor: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SearchField(
                          controller: _doctorSearchController,
                          hintText: 'Search Doctor...',
                          onChanged: (val) => setState(() => _doctorSearch = val),
                          showClear: _doctorSearch.isNotEmpty,
                          onClear: () {
                            _doctorSearchController.clear();
                            setState(() => _doctorSearch = '');
                          },
                          prefixIcon: const Icon(Icons.medical_services_rounded, color: AppTheme.neutralMedium),
                          backgroundColor: AppTheme.cardWhite,
                          borderColor: const Color(0xFFE2E8F0),
                          hintColor: AppTheme.neutralLight,
                          textColor: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Date Picker button
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: _selectedDate != null ? AppTheme.primarySurface : AppTheme.cardWhite,
                          border: Border.all(
                            color: _selectedDate != null ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.calendar_month_rounded,
                            color: _selectedDate != null ? AppTheme.primaryColor : AppTheme.neutralMedium,
                          ),
                          tooltip: 'Filter by date',
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                    ],
                  ),
                ),

                // Specialty filter dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Text(
                        'Specialty: ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.neutralDark),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySurface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(color: AppTheme.primaryColor, width: 1.2),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSpecialty,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
                              items: specialties.map((spec) {
                                return DropdownMenuItem(
                                  value: spec,
                                  child: Text(
                                    spec,
                                    style: const TextStyle(fontSize: 13, color: AppTheme.neutralDark),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedSpecialty = val ?? 'All');
                              },
                            ),
                          ),
                        ),
                      ),
                      if (_selectedDate != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Date: ${_selectedDate!.day}/${_selectedDate!.month}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => setState(() => _selectedDate = null),
                                child: const Icon(Icons.cancel_rounded, size: 14, color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: _statuses.map((status) {
                      final isSelected = _selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(status),
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
                              setState(() => _selectedStatus = status);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Appointments List
                Expanded(
                  child: filteredList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            return _buildAppointmentCard(context, filteredList[index], users);
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error loading user specialties: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading appointments: $e')),
    );
  }

  Widget _buildSummaryStatCard(String label, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppTheme.neutralMedium, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: AppTheme.neutralLight),
            SizedBox(height: 16),
            Text(
              'No appointments found.',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neutralMedium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, AppointmentModel appointment, List<UserModel> users) {
    final theme = Theme.of(context);
    final date = appointment.appointmentDate;
    final formattedDate = '${date.day}/${date.month}/${date.year}';
    final formattedTime = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    // Get doctor specialty
    final doctor = users.firstWhere(
      (u) => u.uid == appointment.doctorId || u.email == appointment.doctorEmail,
      orElse: () => UserModel(
        uid: '',
        fullName: 'Unknown',
        email: '',
        phone: '',
        role: UserRole.patient,
        createdAt: DateTime.now(),
      ),
    );
    final String specialty = doctor.specialty?.isNotEmpty == true ? doctor.specialty! : 'General Practitioner';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: const BorderSide(color: AppTheme.neutralSurface, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Header (Patient/Doctor & Status)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 16, color: AppTheme.infoColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              appointment.patientName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.neutralDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.medical_services_rounded, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Dr. ${appointment.doctorName} ($specialty)',
                              style: const TextStyle(fontSize: 13, color: AppTheme.neutralMedium),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(appointment.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    appointment.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(appointment.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Date & Reason
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 15, color: AppTheme.neutralLight),
                const SizedBox(width: 8),
                Text(
                  '$formattedDate at $formattedTime',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.neutralDark),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.question_answer_rounded, size: 15, color: AppTheme.neutralLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reason: ${appointment.reason}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.neutralMedium),
                  ),
                ),
              ],
            ),

            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded, size: 15, color: AppTheme.neutralLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notes: ${appointment.notes}',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return AppTheme.statusPendingText;
      case 'approved': return AppTheme.statusApprovedText;
      case 'completed': return AppTheme.statusCompletedText;
      case 'cancelled':
      case 'rejected': return AppTheme.statusRejectedText;
      default: return AppTheme.neutralMedium;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return AppTheme.statusPending;
      case 'approved': return AppTheme.statusApproved;
      case 'completed': return AppTheme.statusCompleted;
      case 'cancelled':
      case 'rejected': return AppTheme.statusRejected;
      default: return AppTheme.neutralSurface;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2028),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.neutralDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }
}
