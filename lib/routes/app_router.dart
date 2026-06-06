import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

/// Provides the [GoRouter] instance with auth-aware redirect logic.
final routerProvider = Provider<GoRouter>((ref) {
  // Rebuild router whenever auth state changes.
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    // ── Redirect guard ────────────────────────────────────────────────
    redirect: (context, state) {
      final isLoggedIn = authState.whenData((user) => user != null).value ?? false;
      final currentPath = state.uri.path;

      const publicRoutes = ['/', '/login', '/register', '/forgot-password'];
      final isPublicRoute = publicRoutes.contains(currentPath);

      // If not logged in and trying to access a protected route → login.
      if (!isLoggedIn && !isPublicRoute) {
        return '/login';
      }

      // If logged in and on an auth page → home.
      if (isLoggedIn && (currentPath == '/login' || currentPath == '/register')) {
        return '/home';
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
    ],
  );
});
