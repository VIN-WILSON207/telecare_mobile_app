import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages FCM token registration, refresh, and retry-on-failure logic.
///
/// Usage:
/// 1. Call [initialize] once at app startup.
/// 2. Call [registerToken] after a successful login, passing the user's UID.
/// 3. Call [dispose] when the service is no longer needed.
class FcmService with WidgetsBindingObserver {
  FcmService({
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
  })  : _messaging = messaging,
        _firestore = firestore,
        _prefs = prefs;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  static const _retryKey = 'fcm_retry_count';
  static const _maxRetries = 3;

  /// The UID of the last successfully authenticated user.
  String? _lastUid;

  /// The most recently obtained FCM token (used for retries).
  String? _pendingToken;

  StreamSubscription<String>? _tokenRefreshSub;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Called once at app startup.
  ///
  /// Attaches a token-refresh listener and registers this instance as a
  /// [WidgetsBindingObserver] so foreground-resume events trigger pending
  /// retries.
  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);

    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[FcmService] Token refreshed.');
      _pendingToken = newToken;
      if (_lastUid != null) {
        await _writeToken(_lastUid!, newToken);
      }
    });
  }

  /// Called by [AuthNotifier] after a successful login.
  ///
  /// Requests notification permission, fetches the FCM token, and writes it
  /// to Firestore. Returns silently on permission denial or token errors —
  /// the app is never blocked.
  Future<void> registerToken(String uid) async {
    _lastUid = uid;

    try {
      // 1. Request permission (required on iOS and Android 13+).
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Requirement 1.6 — denied permission: return silently, no token stored.
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FcmService] Notification permission denied. Skipping token registration.');
        return;
      }

      // 2. Fetch token.
      final token = await _messaging.getToken();

      // Requirement 1.7 — null token (network/service failure): schedule retry.
      if (token == null) {
        debugPrint('[FcmService] FCM token is null. Will retry on next foreground.');
        return;
      }

      _pendingToken = token;

      // 3. Write to Firestore.
      await _writeToken(uid, token);
    } catch (e) {
      // Requirement 1.7 — getToken() threw: log, schedule retry, do not block.
      debugPrint('[FcmService] registerToken error: $e. Will retry on next foreground.');
    }
  }

  /// Cleans up the token-refresh subscription and lifecycle observer.
  void dispose() {
    _tokenRefreshSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  // ---------------------------------------------------------------------------
  // WidgetsBindingObserver
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _retryIfNeeded();
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Writes [token] to `users/{uid}` with merge semantics.
  ///
  /// On success the retry counter is reset to 0.
  /// On failure the counter is incremented up to [_maxRetries]; once the
  /// ceiling is reached further retries are suppressed.
  Future<void> _writeToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );

      // Requirement 1.4 — reset counter on success.
      await _prefs.setInt(_retryKey, 0);
      debugPrint('[FcmService] FCM token written for uid=$uid');
    } catch (e) {
      final retryCount = _prefs.getInt(_retryKey) ?? 0;
      debugPrint(
        '[FcmService] Failed to write FCM token (attempt ${retryCount + 1}): $e',
      );

      if (retryCount < _maxRetries) {
        // Requirement 1.4 — increment counter; retry on next foreground.
        await _prefs.setInt(_retryKey, retryCount + 1);
      } else {
        // Requirement 1.4 — max retries reached; stop.
        debugPrint('[FcmService] Max retries ($_maxRetries) reached. Stopping.');
      }
    }
  }

  /// Triggered on every [AppLifecycleState.resumed] event.
  ///
  /// Retries the pending Firestore write if there is an outstanding retry count,
  /// re-fetching the token from FCM if [_pendingToken] is no longer available.
  Future<void> _retryIfNeeded() async {
    final retryCount = _prefs.getInt(_retryKey) ?? 0;

    // Nothing to retry, or ceiling already reached.
    if (retryCount <= 0 || retryCount > _maxRetries) return;

    debugPrint('[FcmService] Retrying FCM token write on foreground (attempt $retryCount).');

    if (_lastUid != null && _pendingToken != null) {
      await _writeToken(_lastUid!, _pendingToken!);
    } else if (_lastUid != null) {
      // Re-fetch token when _pendingToken was lost (e.g., process restart).
      try {
        final token = await _messaging.getToken();
        if (token != null) {
          _pendingToken = token;
          await _writeToken(_lastUid!, token);
        }
      } catch (e) {
        debugPrint('[FcmService] Retry token fetch failed: $e');
      }
    }
  }
}
