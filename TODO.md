# TODO - Router/Verification/OTP Cleanup

- [x] Update VerificationGuard to remove doctor-only helper naming and ensure it supports all healthcare professional roles.
- [x] Remove OTP verification/resend logic from PhoneOtpScreen (system must not perform OTP verification anymore).
- [x] Ensure post-auth navigation routes rely only on `user.role.requiresVerification` and `user.verificationStatus` for all HP roles.
- [x] Ensure any router/guard logic does not rely on doctor-only checks; it should use `user.role.isHealthcareProfessional` / `requiresVerification`.

- [x] Add/adjust unit tests for VerificationGuard helpers to cover nurses/lab technicians.

# TODO - Build/Test unblockers (from current failures)
- [x] Fix parsing/syntax error in `lib/core/widgets/error_view.dart`.
- [x] Add missing dev_dependencies for Mockito in `pubspec.yaml`.
- [x] Fix `lib/core/errors/app_exceptions.dart` so `handleGuardedCall` no longer throws/creates a sealed type in a way that triggers the abstract/sealed instantiation error.
- [ ] Run `dart run build_runner build` (generate `test/auth_repository_test.mocks.dart`).
- [ ] Run `dart test` (or `flutter test`) and address any remaining compilation/test failures.


