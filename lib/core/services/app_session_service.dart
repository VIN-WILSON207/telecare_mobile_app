import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists small pieces of app session data locally on the device.
///
/// Used for:
/// - first-install splash behavior
/// - inactivity timeout routing
/// - last visited route (for “previous screen” behavior)
class AppSessionService {
  AppSessionService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _keyFirstInstallDone = 'app.first_install_done';
  static const _keyLastActivityMs = 'app.last_activity_ms';
  static const _keyLastRoute = 'app.last_route';

  // ---------------------------------------------------------------------------
  // First install
  // ---------------------------------------------------------------------------

  Future<bool> isFirstInstall() async {
    final value = await _storage.read(key: _keyFirstInstallDone);
    return value != 'true';
  }

  Future<void> markFirstInstallDone() async {
    await _storage.write(key: _keyFirstInstallDone, value: 'true');
  }

  // ---------------------------------------------------------------------------
  // Inactivity
  // ---------------------------------------------------------------------------

  Future<DateTime?> getLastActivity() async {
    final value = await _storage.read(key: _keyLastActivityMs);
    if (value == null) return null;
    final ms = int.tryParse(value);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastActivity(DateTime dateTime) async {
    await _storage.write(
      key: _keyLastActivityMs,
      value: dateTime.millisecondsSinceEpoch.toString(),
    );
  }

  // ---------------------------------------------------------------------------
  // Last route
  // ---------------------------------------------------------------------------

  Future<String?> getLastRoute() async {
    return _storage.read(key: _keyLastRoute);
  }

  Future<void> setLastRoute(String route) async {
    await _storage.write(key: _keyLastRoute, value: route);
  }
}

