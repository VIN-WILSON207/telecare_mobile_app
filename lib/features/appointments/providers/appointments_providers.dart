import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/models/user_model.dart';
import '../data/models/appointment_model.dart';
import '../data/repositories/appointment_repository.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository();
});

final verifiedDoctorsProvider = FutureProvider<List<UserModel>>((ref) async {
  return ref.read(appointmentRepositoryProvider).getVerifiedDoctors();
});

final patientAppointmentsProvider = StreamProvider.autoDispose
    .family<List<AppointmentModel>, String>((ref, patientId) {
  return ref
      .watch(appointmentRepositoryProvider)
      .appointmentsForPatient(patientId);
});

final doctorAppointmentsProvider = StreamProvider.autoDispose
    .family<List<AppointmentModel>, String>((ref, doctorId) {
  return ref
      .watch(appointmentRepositoryProvider)
      .appointmentsForDoctor(doctorId);
});
