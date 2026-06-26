import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exposes the [SharedPreferences] instance.
/// 
/// This provider must be overridden in the [ProviderScope] inside `main.dart`
/// with the asynchronously pre-initialized [SharedPreferences] instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope.');
});
