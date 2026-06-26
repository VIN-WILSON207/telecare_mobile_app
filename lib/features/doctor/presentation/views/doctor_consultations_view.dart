import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../appointments/providers/appointments_providers.dart';
import '../../../../core/theme/app_theme.dart';

class DoctorConsultationsView extends ConsumerWidget {
  final UserModel user;

  const DoctorConsultationsView({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider(user.uid));

    final activeConsultations = appointmentsAsync.maybeWhen(
      data: (list) => list.where((a) => a.status.toLowerCase() == 'approved').toList(),
      orElse: () => <dynamic>[],
    );

    final historyConsultations = appointmentsAsync.maybeWhen(
      data: (list) => list.where((a) => a.status.toLowerCase() == 'completed').toList(),
      orElse: () => <dynamic>[],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async {
          ref.invalidate(doctorAppointmentsProvider(user.uid));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active consultations
              const Text(
                'Active Sessions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.neutralDark),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select a patient from approved slots to start the video room',
                style: TextStyle(fontSize: 11, color: AppTheme.neutralLight),
              ),
              const SizedBox(height: 16),
              if (activeConsultations.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.video_camera_back_outlined, size: 40, color: AppTheme.neutralLight),
                      SizedBox(height: 8),
                      Text(
                        'No active consultation sessions scheduled.',
                        style: TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: activeConsultations.map((a) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primarySurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.video_call_rounded, color: AppTheme.primaryColor, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.patientName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.neutralDark),
                                ),
                                Text(
                                  'Reason: ${a.reason}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.neutralMedium),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Initializing secure video consultation session via Jitsi Meet...')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Start', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 32),

              // Consultation history
              const Text(
                'Consultation History Log',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.neutralDark),
              ),
              const SizedBox(height: 12),
              if (historyConsultations.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.history_rounded, size: 40, color: AppTheme.neutralLight),
                      SizedBox(height: 8),
                      Text(
                        'No consultation logs found.',
                        style: TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: historyConsultations.map((a) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                a.patientName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.neutralDark),
                              ),
                              const Text(
                                'Completed',
                                style: TextStyle(color: AppTheme.successColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.neutralLight),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(a.appointmentDate),
                                style: const TextStyle(fontSize: 11, color: AppTheme.neutralMedium),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: const [
                              Icon(Icons.timer_outlined, size: 12, color: AppTheme.neutralLight),
                              SizedBox(width: 6),
                              Text(
                                'Duration: 18 mins 30 secs',
                                style: TextStyle(fontSize: 11, color: AppTheme.neutralMedium),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} at $h:$m';
  }
}
