import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/admin_repository.dart';

import '../../auth/providers/auth_providers.dart';
import '../../auth/data/models/user_model.dart';
import '../../appointments/data/models/appointment_model.dart';
import '../../verification/data/models/verification_request_model.dart';
import '../models/audit_log_model.dart';

/// Provides the singleton [AdminRepository] instance.
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(
    firestore: ref.watch(firestoreProvider),
  );
});

/// Exposes all users in the system in real time.
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getUsersStream();
});

/// Exposes all appointments in real time.
final allAppointmentsProvider = StreamProvider<List<AppointmentModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getAppointmentsStream();
});

/// Exposes all doctor verification requests in real time.
final allVerificationRequestsProvider =
    StreamProvider<List<VerificationRequestModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getAllVerificationRequestsStream();
});

/// Exposes all audit logs in real time.
final auditLogsProvider = StreamProvider<List<AuditLogModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getAuditLogsStream();
});

/// Active admin tab index.
final adminActiveTabProvider =
    NotifierProvider<AdminActiveTabNotifier, int>(AdminActiveTabNotifier.new);

/// Tracks the selected navigation screen index:
///  0: Dashboard
///  1: Doctor Verification
///  2: Users
///  3: Appointments
///  4: Consultations
///  5: Analytics
///  6: Reports
///  7: Security Center
///  8: Audit Logs
///  9: Notifications
/// 10: Health Content
/// 11: Feedback & Complaints
/// 12: Settings
/// 13: Backup & Recovery
/// 14: Admin Profile
class AdminActiveTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    state = index;
  }
}
