import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/phone_otp_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/auth/providers/auth_state.dart';
import '../features/appointments/presentation/appointments_screen.dart';
import '../features/consultation/presentation/consultations_screen.dart';
import '../features/doctor/presentation/patients_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/profile_screen.dart';
import '../features/medical_records/presentation/medical_records_screen.dart';
import '../features/patient/presentation/messages_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/verification/presentation/screens/verification_status_screen.dart';
import '../features/verification/presentation/screens/submit_verification_screen.dart';
import '../features/verification/presentation/screens/pending_verifications_screen.dart';
import '../features/verification/presentation/screens/verification_review_screen.dart';

/// A notifier that triggers GoRouter redirects when AuthState changes.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authNotifierProvider,
      (_, _) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Provides the [GoRouter] instance with auth-aware redirect logic.
final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  // Determine initial route dynamically on cold start
  String initialRoute = '/';
  final isFirstInstall = prefs.getBool('is_first_install') ?? true;

  if (isFirstInstall) {
    initialRoute = '/';
  } else {
    // Check session timeout
    final lastActivityStr = prefs.getString('last_activity_timestamp');
    bool sessionExpired = true;
    if (lastActivityStr != null) {
      final lastActivity = DateTime.parse(lastActivityStr);
      final difference = DateTime.now().difference(lastActivity);
      if (difference.inMinutes < 30) {
        sessionExpired = false;
      }
    }

    if (sessionExpired) {
      initialRoute = '/login';
    } else {
      // Check if user is logged in
      final currentUser = ref.read(firebaseAuthProvider).currentUser;
      if (currentUser != null) {
        // Always restore to /home — never to sub-screens which need
        // a valid nav-stack underneath them.
        initialRoute = '/home';
      } else {
        initialRoute = '/login';
      }
    }
  }

  return GoRouter(
    initialLocation: initialRoute,
    debugLogDiagnostics: true,
    refreshListenable: routerNotifier,

    // ── Redirect guard ────────────────────────────────────────────────
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);

      if (authState is AuthInitial || authState is AuthLoading) {
        return null; // wait for auth state to load
      }

      final currentPath = state.uri.path;

      // If authState is AuthSplash, stay on splash screen
      if (authState is AuthSplash) {
        if (currentPath != '/') {
          return '/';
        }
        return null;
      }

      // If authState is AuthOtpSent, force navigate to /phone-otp
      if (authState is AuthOtpSent) {
        if (currentPath != '/phone-otp') {
          return '/phone-otp';
        }
        return null;
      }

      final isLoggedIn = authState is AuthAuthenticated;

      // Routes that don't require authentication
      const authRoutes = ['/login', '/register', '/forgot-password', '/phone-otp'];
      final isAuthRoute = authRoutes.contains(currentPath);
      final isSplash = currentPath == '/';

      // 1. If not logged in
      if (!isLoggedIn) {
        // If on splash, only redirect to login if it is NOT the first install
        if (isSplash) {
          final prefs = ref.read(sharedPreferencesProvider);
          final isFirstInstall = prefs.getBool('is_first_install') ?? true;
          if (isFirstInstall) {
            return null; // Stay on splash to let it play the animation
          } else {
            return '/login';
          }
        }
        if (currentPath == '/phone-otp') {
          return '/login';
        }
        if (!isAuthRoute) return '/login';
        return null;
      }

      // 2. User is logged in
      final user = authState.user;
      final isDoctor = user.role.value == 'doctor';
      final isVerified = user.verificationStatus.toLowerCase() == 'approved';

      // If user is authenticated and navigating to a valid app route, save it
      const systemRoutes = ['/', '/login', '/register', '/forgot-password', '/verification-status', '/phone-otp'];
      if (!systemRoutes.contains(currentPath)) {
        final prefs = ref.read(sharedPreferencesProvider);
        prefs.setString('last_route', currentPath).catchError((_) => false);
      }

      // If on splash or auth page, redirect to appropriate landing page
      if (isSplash || isAuthRoute) {
        if (isDoctor && !isVerified) {
          return '/verification-status';
        }
        return '/home';
      }

      // Verification routes are public to logged-in doctors
      if (currentPath == '/verification-status' || currentPath == '/submit-verification') {
        if (!isDoctor) return '/home'; // patients/admins don't need verification status
        if (isVerified && currentPath == '/submit-verification') return '/verification-status';
        return null;
      }

      // If doctor is unverified, restrict access to appointments, consultations, and home
      const restrictedDoctorRoutes = [
        '/home',
        '/appointments',
        '/consultations',
        '/patients',
        '/medical-records',
      ];
      if (isDoctor && !isVerified && restrictedDoctorRoutes.contains(currentPath)) {
        return '/verification-status';
      }

      return null; // no redirect
    },

    // ── Routes ────────────────────────────────────────────────────────
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/phone-otp',
        name: 'phoneOtp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final verificationId = extra?['verificationId'] as String? ?? '';
          final phone = extra?['phone'] as String? ?? '';
          return PhoneOtpScreen(
            verificationId: verificationId,
            phone: phone,
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/verification-status',
        name: 'verificationStatus',
        builder: (context, state) => const VerificationStatusScreen(),
      ),
      GoRoute(
        path: '/submit-verification',
        name: 'submitVerification',
        builder: (context, state) => const SubmitVerificationScreen(),
      ),
      GoRoute(
        path: '/admin/pending-verifications',
        name: 'pendingVerifications',
        builder: (context, state) => const PendingVerificationsScreen(),
      ),
      GoRoute(
        path: '/admin/review-verification/:requestId',
        name: 'reviewVerification',
        builder: (context, state) {
          final requestId = state.pathParameters['requestId'] ?? '';
          return VerificationReviewScreen(requestId: requestId);
        },
      ),

      GoRoute(
        path: '/appointments',
        name: 'appointments',
        builder: (context, state) => const AppointmentsScreen(),
      ),
      GoRoute(
        path: '/messages',
        name: 'messages',
        builder: (context, state) => const MessagesScreen(),
      ),
      GoRoute(
        path: '/consultations',
        name: 'consultations',
        builder: (context, state) => const ConsultationsScreen(),
      ),
      GoRoute(
        path: '/patients',
        name: 'patients',
        builder: (context, state) => const PatientsScreen(),
      ),
      GoRoute(
        path: '/medical-records',
        name: 'medicalRecords',
        builder: (context, state) => const MedicalRecordsScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
