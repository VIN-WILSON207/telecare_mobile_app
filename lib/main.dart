import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/notification_service.dart';
import 'core/services/service_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/firestore_seeder.dart';
import 'features/auth/providers/auth_providers.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[Main] Initialization started');

  try {
    await dotenv.load(fileName: '.env');
    debugPrint('[Main] .env loaded');
  } catch (e) {
    debugPrint('[Main] Warning: Failed to load .env file: $e');
  }

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('[Main] Firebase initialized');
    
    // Seed Firestore in the background to avoid blocking the UI startup
    FirestoreSeeder.seed().catchError((e) {
      debugPrint('[Main] Firestore seeding failed: $e');
    });
  } catch (e) {
    debugPrint('[Main] Firebase initialization failed: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final notificationService = NotificationService(
    firestore: FirebaseFirestore.instance,
  );
  debugPrint('[Main] Services initialized');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: TeleCareApp(notificationService: notificationService),
    ),
  );
  debugPrint('[Main] runApp called');
}

class TeleCareApp extends ConsumerWidget {
  final NotificationService notificationService;

  const TeleCareApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return Listener(
      onPointerDown: (_) =>
          ref.read(authNotifierProvider.notifier).updateActivity(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'TeleCare',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('fr'),
        ],
        routerConfig: router,
      ),
    );
  }
}
