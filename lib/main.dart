import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/service_providers.dart';
import 'features/auth/providers/auth_providers.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'core/utils/firestore_seeder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: Failed to load .env file: $e');
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize and seed sample collections programmatically into Firestore.
  await FirestoreSeeder.seed();

  final prefs = await SharedPreferences.getInstance();

  // ── FCM Service ──────────────────────────────────────────────────────────────
  final fcmService = FcmService(
    messaging: FirebaseMessaging.instance,
    firestore: FirebaseFirestore.instance,
    prefs: prefs,
  );
  await fcmService.initialize();

  // ── Notification Service ─────────────────────────────────────────────────────
  final fcmServerKey = dotenv.env['FCM_SERVER_KEY'] ?? '';
  final notificationService = NotificationService(
    localNotifications: FlutterLocalNotificationsPlugin(),
    messaging: FirebaseMessaging.instance,
    firestore: FirebaseFirestore.instance,
    dio: Dio(),
    fcmServerKey: fcmServerKey,
  );
  await notificationService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        fcmServiceProvider.overrideWithValue(fcmService),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: TeleCareApp(notificationService: notificationService),
    ),
  );
}

class TeleCareApp extends ConsumerWidget {
  final NotificationService notificationService;

  const TeleCareApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Wire the router into NotificationService for tap-based navigation
    notificationService.setRouter(router);

    return Listener(
      onPointerDown: (_) => ref.read(authNotifierProvider.notifier).updateActivity(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'TeleCare',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: router,
      ),
    );
  }
}