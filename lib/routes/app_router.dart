import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/auth/providers/auth_state.dart';
import '../features/appointments/presentation/appointments_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/verification/presentation/screens/verification_status_screen.dart';
import '../features/verification/presentation/screens/submit_verification_screen.dart';
import '../features/verification/presentation/screens/pending_verifications_screen.dart';
import '../features/verification/presentation/screens/verification_review_screen.dart';

/// Provides the [GoRouter] instance with auth-aware redirect logic.
final routerProvider = Provider<GoRouter>((ref) {
  // Rebuild router whenever auth state changes.
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    // ── Redirect guard ────────────────────────────────────────────────
    redirect: (context, state) {
      if (authState is AuthInitial || authState is AuthLoading) {
        return null; // wait for auth state to load
      }

      final isLoggedIn = authState is AuthAuthenticated;
      final currentPath = state.uri.path;

      const publicRoutes = ['/', '/login', '/register', '/forgot-password'];
      final isPublicRoute = publicRoutes.contains(currentPath);

      // If not logged in and trying to access a protected route → login.
      if (!isLoggedIn) {
        if (!isPublicRoute) return '/login';
        return null;
      }

      // User is logged in
      final user = authState.user;
      final isDoctor = user.role.value == 'doctor';
      final isVerified = user.verificationStatus.toLowerCase() == 'approved';

      // If logged in and on an auth page → redirect.
      if (currentPath == '/login' || currentPath == '/register') {
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
        '/medical-records'
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

      // Protected placeholder screens for route testing
      GoRoute(
        path: '/appointments',
        name: 'appointments',
        builder: (context, state) => const AppointmentsScreen(),
      ),
      GoRoute(
        path: '/consultations',
        name: 'consultations',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Consultations Screen (Verified Only)')),
        ),
      ),
      GoRoute(
        path: '/medical-records',
        name: 'medicalRecords',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Medical Records Screen (Verified Only)')),
        ),
      ),
    ],
  );
});
