import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'features/auth/providers/auth_providers.dart';
import 'core/theme/app_theme.dart';

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

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TeleCareApp(),
    ),
  );
}

class TeleCareApp extends ConsumerWidget {
  const TeleCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

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