import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_role.dart';
import '../../providers/admin_providers.dart';

class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(allUsersProvider);
    final appointmentsAsync = ref.watch(allAppointmentsProvider);
    final requestsAsync = ref.watch(allVerificationRequestsProvider);

    return usersAsync.when(
      data: (users) {
        return appointmentsAsync.when(
          data: (appointments) {
            return requestsAsync.when(
              data: (requests) {
                // 1. Users by Role
                final patientsCount =
                    users.where((u) => u.role == UserRole.patient).length;
                final doctorsCount =
                    users.where((u) => u.role == UserRole.doctor).length;
                final adminsCount =
                    users.where((u) => u.role == UserRole.admin).length;
                final totalUsers = patientsCount + doctorsCount + adminsCount;

                // 2. Appointment Stats
                final pendingAppts = appointments
                    .where((a) => a.status.toLowerCase() == 'pending')
                    .length;
                final approvedAppts = appointments
                    .where((a) => a.status.toLowerCase() == 'approved')
                    .length;
                final completedAppts = appointments
                    .where((a) => a.status.toLowerCase() == 'completed')
                    .length;
                final cancelledAppts = appointments
                    .where((a) =>
                        a.status.toLowerCase() == 'cancelled' ||
                        a.status.toLowerCase() == 'rejected')
                    .length;
                final totalAppointments = appointments.length;

                // 3. Verification Trends
                final pendingVerif =
                    requests.where((r) => r.status == 'pending').length;
                final approvedVerif =
                    requests.where((r) => r.status == 'approved').length;
                final rejectedVerif =
                    requests.where((r) => r.status == 'rejected').length;

                // 4. Doctors by Specialty
                final specialtyMap = <String, int>{};
                for (var doctor
                    in users.where((u) => u.role == UserRole.doctor)) {
                  final spec = doctor.specialty?.trim();
                  if (spec != null && spec.isNotEmpty) {
                    specialtyMap[spec] = (specialtyMap[spec] ?? 0) + 1;
                  } else {
                    specialtyMap['Unspecified'] =
                        (specialtyMap['Unspecified'] ?? 0) + 1;
                  }
                }
                final specialtiesSorted = specialtyMap.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                // 5. Active doctors count
                final activeDoctors = users
                    .where((u) =>
                        u.role == UserRole.doctor &&
                        u.verificationStatus == 'approved')
                    .length;

                // 6. Today's consultations
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final todayConsultations = appointments
                    .where((a) =>
                        a.status.toLowerCase() == 'completed' &&
                        a.appointmentDate.year == now.year &&
                        a.appointmentDate.month == now.month &&
                        a.appointmentDate.day == now.day)
                    .length;

                // 7. Daily registrations trend (last 7 days)
                final last7Days = List.generate(
                    7, (i) => today.subtract(Duration(days: 6 - i)));
                final dayLabels = last7Days.map((d) {
                  final weekdays = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun'
                  ];
                  return weekdays[d.weekday - 1];
                }).toList();

                final dailyRegistrations = last7Days.map((date) {
                  return users
                      .where((u) =>
                          u.createdAt.year == date.year &&
                          u.createdAt.month == date.month &&
                          u.createdAt.day == date.day)
                      .length;
                }).toList();

                // 8. Consultations per day (last 7 days)
                final consultationsPerDay = last7Days.map((date) {
                  return appointments
                      .where((a) =>
                          a.status.toLowerCase() == 'completed' &&
                          a.appointmentDate.year == date.year &&
                          a.appointmentDate.month == date.month &&
                          a.appointmentDate.day == date.day)
                      .length;
                }).toList();

                // 9. Find most active doctor
                String mostActiveDoctorName = 'N/A';
                int maxDoctorConsultations = 0;
                final doctorApptCount = <String, int>{};
                for (var appt in appointments
                    .where((a) => a.status.toLowerCase() == 'completed')) {
                  doctorApptCount[appt.doctorName] =
                      (doctorApptCount[appt.doctorName] ?? 0) + 1;
                }
                if (doctorApptCount.isNotEmpty) {
                  final sorted = doctorApptCount.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  mostActiveDoctorName = sorted.first.key;
                  maxDoctorConsultations = sorted.first.value;
                }

                // 10. Avg consultations per day (this month)
                final completedThisMonth = appointments
                    .where((a) =>
                        a.status.toLowerCase() == 'completed' &&
                        a.appointmentDate.year == now.year &&
                        a.appointmentDate.month == now.month)
                    .length;
                final avgConsultationsPerDay =
                    now.day > 0 ? (completedThisMonth / now.day) : 0.0;

                // 11. Growth indicators (this month vs last month)
                final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
                final lastMonth = now.month == 1 ? 12 : now.month - 1;

                final thisMonthUsersCount = users
                    .where((u) =>
                        u.createdAt.year == now.year &&
                        u.createdAt.month == now.month)
                    .length;
                final lastMonthUsersCount = users
                    .where((u) =>
                        u.createdAt.year == lastMonthYear &&
                        u.createdAt.month == lastMonth)
                    .length;
                final userGrowth = lastMonthUsersCount > 0
                    ? ((thisMonthUsersCount - lastMonthUsersCount) /
                        lastMonthUsersCount *
                        100)
                    : (thisMonthUsersCount > 0 ? 100.0 : 0.0);

                final thisMonthBookings = appointments
                    .where((a) =>
                        a.createdAt.year == now.year &&
                        a.createdAt.month == now.month)
                    .length;
                final lastMonthBookings = appointments
                    .where((a) =>
                        a.createdAt.year == lastMonthYear &&
                        a.createdAt.month == lastMonth)
                    .length;
                final bookingGrowth = lastMonthBookings > 0
                    ? ((thisMonthBookings - lastMonthBookings) /
                        lastMonthBookings *
                        100)
                    : (thisMonthBookings > 0 ? 100.0 : 0.0);

                final activeUsersCount = users.where((u) => u.isActive).length;
                final thisMonthActiveUsersCount = users
                    .where((u) =>
                        u.isActive &&
                        u.createdAt.year == now.year &&
                        u.createdAt.month == now.month)
                    .length;
                final lastMonthActiveUsersCount = users
                    .where((u) =>
                        u.isActive &&
                        u.createdAt.year == lastMonthYear &&
                        u.createdAt.month == lastMonth)
                    .length;
                final activeUserGrowth = lastMonthActiveUsersCount > 0
                    ? ((thisMonthActiveUsersCount - lastMonthActiveUsersCount) /
                        lastMonthActiveUsersCount *
                        100)
                    : (thisMonthActiveUsersCount > 0 ? 100.0 : 0.0);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with gradient accent
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          boxShadow: AppTheme.elevatedShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Analytics & Metrics',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Aggregate analytics from system databases',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Summary Cards (2x2 Grid) ──
                      _buildSectionHeader(context, 'Overview', Icons.dashboard_rounded),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              title: 'Total Users',
                              value: '$totalUsers',
                              icon: Icons.people_alt_rounded,
                              color: AppTheme.infoColor,
                              trend: '${userGrowth >= 0 ? '+' : ''}${userGrowth.toStringAsFixed(1)}%',
                              trendUp: userGrowth >= 0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              title: 'Active Doctors',
                              value: '$activeDoctors',
                              icon: Icons.medical_services_rounded,
                              color: AppTheme.primaryColor,
                              trend: '+$doctorsCount total',
                              trendUp: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              title: 'Total Appointments',
                              value: '$totalAppointments',
                              icon: Icons.calendar_month_rounded,
                              color: AppTheme.accentColor,
                              trend: '$completedAppts completed',
                              trendUp: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              title: 'Consultations Today',
                              value: '$todayConsultations',
                              icon: Icons.video_call_rounded,
                              color: AppTheme.warningColor,
                              trend: 'Live',
                              trendUp: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Daily Registrations Trend ──
                      _buildSectionHeader(context, 'Daily Registrations (Last 7 Days)', Icons.trending_up_rounded),
                      const SizedBox(height: 12),
                      _buildAnalyticsCard(
                        context,
                        title: 'Registration Trend',
                        subtitle: 'New user sign-ups per day',
                        child: Column(
                          children: [
                            SizedBox(
                              height: 160,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(7, (index) {
                                  final maxVal = dailyRegistrations.reduce((a, b) => a > b ? a : b);
                                  final barHeight = maxVal > 0
                                      ? (dailyRegistrations[index] / maxVal) * 115
                                      : 5.0;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${dailyRegistrations[index]}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.neutralMedium,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            height: barHeight,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppTheme.primaryColor.withValues(alpha: 0.7),
                                                  AppTheme.primaryColor,
                                                ],
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                              ),
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(4),
                                                topRight: Radius.circular(4),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            dayLabels[index],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.neutralLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Consultations Per Day ──
                      _buildAnalyticsCard(
                        context,
                        title: 'Consultations Per Day',
                        subtitle: 'Completed consultation sessions this week',
                        child: Column(
                          children: [
                            SizedBox(
                              height: 160,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(7, (index) {
                                  final maxVal = consultationsPerDay.reduce((a, b) => a > b ? a : b);
                                  final barHeight = maxVal > 0
                                      ? (consultationsPerDay[index] / maxVal) * 115
                                      : 5.0;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${consultationsPerDay[index]}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.neutralMedium,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            height: barHeight,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppTheme.accentColor.withValues(alpha: 0.7),
                                                  AppTheme.accentColor,
                                                ],
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                              ),
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(4),
                                                topRight: Radius.circular(4),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            dayLabels[index],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.neutralLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Doctor Activity Metrics ──
                      _buildSectionHeader(context, 'Doctor Activity', Icons.local_hospital_rounded),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              context,
                              icon: Icons.star_rounded,
                              label: 'Most Active Doctor',
                              value: mostActiveDoctorName,
                              subValue: '$maxDoctorConsultations consultations total',
                              color: AppTheme.warningColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricTile(
                              context,
                              icon: Icons.speed_rounded,
                              label: 'Avg. Consultations/Day',
                              value: avgConsultationsPerDay.toStringAsFixed(1),
                              subValue: 'This month average',
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── User Base Breakdown ──
                      _buildSectionHeader(context, 'User Base Breakdown', Icons.people_alt_rounded),
                      const SizedBox(height: 12),
                      _buildAnalyticsCard(
                        context,
                        title: 'User Base Breakdown',
                        subtitle: 'Distribution of system users ($totalUsers total)',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildLegendItem('Patients', patientsCount, AppTheme.infoColor),
                                const SizedBox(width: 14),
                                _buildLegendItem('Doctors', doctorsCount, AppTheme.primaryColor),
                                const SizedBox(width: 14),
                                _buildLegendItem('Admins', adminsCount, AppTheme.accentAlt),
                              ],
                            ),
                            const SizedBox(height: 18),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 20,
                                child: Row(
                                  children: [
                                    if (patientsCount > 0)
                                      Expanded(
                                        flex: patientsCount,
                                        child: Container(color: AppTheme.infoColor),
                                      ),
                                    if (doctorsCount > 0)
                                      Expanded(
                                        flex: doctorsCount,
                                        child: Container(color: AppTheme.primaryColor),
                                      ),
                                    if (adminsCount > 0)
                                      Expanded(
                                        flex: adminsCount,
                                        child: Container(color: AppTheme.accentAlt),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Appointment Trends ──
                      _buildSectionHeader(context, 'Appointment Trends', Icons.calendar_month_rounded),
                      const SizedBox(height: 12),
                      _buildAnalyticsCard(
                        context,
                        title: 'Appointment Status',
                        subtitle: 'Overview of scheduled booking statuses ($totalAppointments total)',
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxCount = [
                              pendingAppts,
                              approvedAppts,
                              completedAppts,
                              cancelledAppts
                            ].reduce(
                                (max, current) => current > max ? current : max);

                            return SizedBox(
                              height: 175,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buildBarItem('Pending', pendingAppts, maxCount,
                                        AppTheme.statusPendingText),
                                    _buildBarItem('Approved', approvedAppts,
                                        maxCount, AppTheme.statusApprovedText),
                                    _buildBarItem('Completed', completedAppts,
                                        maxCount, AppTheme.statusCompletedText),
                                    _buildBarItem('Cancelled', cancelledAppts,
                                        maxCount, AppTheme.statusRejectedText),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Verifications & Specialties Row ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildAnalyticsCard(
                              context,
                              title: 'Verifications',
                              subtitle: 'Outcome Trends',
                              child: Column(
                                children: [
                                  _buildRatioRow('Approved', approvedVerif,
                                      requests.length, AppTheme.statusApprovedText),
                                  _buildRatioRow('Rejected', rejectedVerif,
                                      requests.length, AppTheme.statusRejectedText),
                                  _buildRatioRow('Pending', pendingVerif,
                                      requests.length, AppTheme.statusPendingText),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAnalyticsCard(
                              context,
                              title: 'Active Users',
                              subtitle: 'Currently active accounts',
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$activeUsersCount',
                                        style: theme.textTheme.headlineLarge?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: activeUserGrowth >= 0
                                              ? AppTheme.statusApproved
                                              : AppTheme.statusRejected,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                                activeUserGrowth >= 0
                                                    ? Icons.trending_up_rounded
                                                    : Icons.trending_down_rounded,
                                                size: 12,
                                                color: activeUserGrowth >= 0
                                                    ? AppTheme.statusApprovedText
                                                    : AppTheme.statusRejectedText),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${activeUserGrowth >= 0 ? '+' : ''}${activeUserGrowth.toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: activeUserGrowth >= 0
                                                    ? AppTheme.statusApprovedText
                                                    : AppTheme.statusRejectedText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Compared to last month',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.neutralLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Most Common Specialties ──
                      _buildSectionHeader(context, 'Most Common Specialties', Icons.local_hospital_rounded),
                      const SizedBox(height: 12),
                      _buildAnalyticsCard(
                        context,
                        title: 'Doctor Specialties',
                        subtitle: 'Top specializations among registered doctors',
                        child: Column(
                          children: specialtiesSorted.isEmpty
                              ? [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24.0),
                                    child: Center(
                                      child: Text(
                                        'No specialty stats available',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.neutralLight,
                                        ),
                                      ),
                                    ),
                                  )
                                ]
                              : specialtiesSorted.take(6).map((e) {
                                  final maxSpecCount = specialtiesSorted.first.value;
                                  final progress = maxSpecCount > 0
                                      ? e.value / maxSpecCount
                                      : 0.0;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                e.key,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.neutralDark,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 8,
                                                  vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primarySurface,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${e.value}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            color: AppTheme.primaryColor,
                                            backgroundColor:
                                                AppTheme.neutralSurface,
                                            minHeight: 6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Platform Growth Indicators ──
                      _buildSectionHeader(context, 'Platform Growth', Icons.rocket_launch_rounded),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGrowthIndicator(
                              context,
                              label: 'User Growth',
                              percentage: userGrowth,
                              icon: Icons.person_add_rounded,
                              color: AppTheme.infoColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildGrowthIndicator(
                              context,
                              label: 'Booking Growth',
                              percentage: bookingGrowth,
                              icon: Icons.event_available_rounded,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  Center(child: Text('Error loading requests: $e')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) =>
              Center(child: Text('Error loading appointments: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading users: $e')),
    );
  }

  // ── Section Header with gradient icon ──
  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryLight],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.neutralDark,
          ),
        ),
      ],
    );
  }

  // ── Summary Card ──
  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool trendUp,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.neutralSurface, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: trendUp ? AppTheme.statusApproved : AppTheme.statusRejected,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: trendUp
                        ? AppTheme.statusApprovedText
                        : AppTheme.statusRejectedText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutralMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ── Metric Tile ──
  Widget _buildMetricTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String subValue,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.neutralSurface, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutralLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.neutralDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppTheme.neutralMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ── Growth Indicator ──
  Widget _buildGrowthIndicator(
    BuildContext context, {
    required String label,
    required double percentage,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.neutralSurface, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            '+${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutralMedium,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'vs last month',
            style: TextStyle(
              fontSize: 9.5,
              color: AppTheme.neutralLight,
            ),
          ),
        ],
      ),
    );
  }

  // ── Analytics Card ──
  Widget _buildAnalyticsCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.neutralSurface, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.neutralDark,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppTheme.neutralLight,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutralMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildBarItem(String label, int value, int maxCount, Color color) {
    final barHeight = maxCount > 0 ? (value / maxCount) * 95 : 5.0;
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 28,
          height: barHeight > 5 ? barHeight : 5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.6), color],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutralMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildRatioRow(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutralMedium,
                ),
              ),
              Text(
                '$count (${(percentage * 100).toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              color: color,
              backgroundColor: AppTheme.neutralSurface,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
