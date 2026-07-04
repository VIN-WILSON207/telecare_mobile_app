import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

/// Handles local notification display, FCM foreground message queuing,
/// notification tap routing, and client-side push sending via the
/// FCM Legacy HTTP API.
///
/// Usage:
/// 1. Construct with all required dependencies.
/// 2. Call [setRouter] once the [GoRouter] is available (after ProviderScope).
/// 3. Call [initialize] before [runApp] to set up channels and handlers.
/// 4. Call [sendNotification] to push a notification to a specific user.
class NotificationService {
  NotificationService({
    required FlutterLocalNotificationsPlugin localNotifications,
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
    required Dio dio,
    required String fcmServerKey,
  })  : _localNotifications = localNotifications,
        _messaging = messaging,
        _firestore = firestore,
        _dio = dio,
        _fcmServerKey = fcmServerKey;

  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final Dio _dio;

  /// FCM Server Key from Firebase Console → Project Settings → Cloud Messaging.
  final String _fcmServerKey;

  /// GoRouter instance injected after initialization to avoid a circular
  /// dependency (router depends on providers that depend on this service).
  GoRouter? _router;

  bool _initComplete = false;
  bool _initFailed = false;
  final List<RemoteMessage> _messageQueue = [];

  static const _channelId = 'telecare_notifications';
  static const _channelName = 'TeleCare Notifications';

  /// Injects the [GoRouter] instance for tap-based navigation.
  /// Must be called before any notification tap can be handled.
  void setRouter(GoRouter router) {
    _router = router;
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes the local notification plugin, registers foreground/tap
  /// handlers, and flushes any messages that arrived before init completed.
  ///
  /// Must be called before [runApp] so that the plugin is ready when the
  /// first user-navigable screen is rendered (Requirement 5.3).
  Future<void> initialize() async {
    // ── 1. Create Android notification channel ──────────────────────────────
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );

    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(androidChannel);

    // ── 2. Initialize the local notifications plugin ────────────────────────
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    // Requirement 5.4 — if init fails, log, set flag, continue without throw.
    final bool? initResult = await _localNotifications
        .initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped,
        )
        .catchError((Object e) {
      debugPrint('[NotificationService] Local notifications init failed: $e');
      _initFailed = true;
      return false;
    });

    if (initResult == false && !_initFailed) {
      debugPrint(
          '[NotificationService] Local notifications init returned false.');
    }

    // ── 3. Foreground FCM handler ────────────────────────────────────────────
    // Requirement 5.5 — queue messages that arrive before init completes.
    FirebaseMessaging.onMessage.listen((message) {
      if (!_initComplete) {
        _messageQueue.add(message);
      } else {
        _displayMessage(message);
      }
    });

    // ── 4. Tap handlers (background / terminated) ───────────────────────────
    // Requirement 2.4 / 3.6 / 4.6 — route on notification tap.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _routeFromMessage(message.data);
    });

    // App launched from a terminated state via notification tap.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay slightly so the widget tree is fully mounted before routing.
      Future.delayed(const Duration(milliseconds: 500), () {
        _routeFromMessage(initialMessage.data);
      });
    }

    // ── 5. Mark init complete and flush queued messages ──────────────────────
    // Requirement 5.5 — display queued messages in arrival order.
    _initComplete = true;
    for (final msg in _messageQueue) {
      _displayMessage(msg);
    }
    _messageQueue.clear();
  }

  // ---------------------------------------------------------------------------
  // Foreground display
  // ---------------------------------------------------------------------------

  void _displayMessage(RemoteMessage message) {
    // Requirement 5.4 — skip silently when init failed.
    if (_initFailed) return;

    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Main channel for TeleCare notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ---------------------------------------------------------------------------
  // Tap routing
  // ---------------------------------------------------------------------------

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _routeFromMessage(data);
    } catch (_) {
      // Malformed payload — ignore silently.
    }
  }

  void _routeFromMessage(Map<String, dynamic> data) {
    final route = resolveRoute(data);
    if (route != null && _router != null) {
      _router!.go(route);
    }
  }

  /// Returns the in-app route path for a given notification data payload.
  ///
  /// Extracted as a public static method so it can be tested as a pure
  /// function without constructing the full service (Property 4).
  ///
  /// Routing table:
  /// | `data['type']`         | route            |
  /// |------------------------|------------------|
  /// | `appointment_request`  | `/appointments`  |
  /// | `appointment_approved` | `/appointments`  |
  /// | `consultation_started` | `/consultations` |
  static String? resolveRoute(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'appointment_request':
      case 'appointment_approved':
        return '/appointments';
      case 'consultation_started':
        return '/consultations';
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Notification sending — FCM Legacy HTTP API
  // ---------------------------------------------------------------------------

  /// Sends a push notification to a specific user via the FCM Legacy HTTP API.
  ///
  /// Steps:
  /// 1. Reads the target user's `fcmToken` from `users/{targetUserId}`.
  /// 2. POSTs to the FCM legacy endpoint with the server key header.
  /// 3. Retries up to 3 times on transient failures with 1 s / 2 s / 4 s
  ///    back-off. Stops immediately on 401 (auth) or invalid-token errors.
  ///
  /// Requirements: 2.1, 2.2, 2.3, 3.1–3.5, 4.1–4.5.
  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    // ── Step 1: Read FCM token from Firestore ────────────────────────────────
    String? fcmToken;
    try {
      final doc =
          await _firestore.collection('users').doc(targetUserId).get();
      fcmToken = doc.data()?['fcmToken'] as String?;
    } catch (e) {
      debugPrint(
          '[NotificationService] Failed to read fcmToken for $targetUserId: $e');
      return;
    }

    // Requirements 2.3, 3.3, 4.4 — absent token: log warning, skip.
    if (fcmToken == null || fcmToken.isEmpty) {
      debugPrint(
          '[NotificationService] No fcmToken for user $targetUserId. Skipping.');
      return;
    }

    // ── Step 2: Send via FCM Legacy HTTP API (up to 3 retries) ──────────────
    const maxRetries = 3;
    final delays = [1, 2, 4]; // seconds

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _dio.post(
          'https://fcm.googleapis.com/fcm/send',
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'key=$_fcmServerKey',
            },
          ),
          data: jsonEncode({
            'to': fcmToken,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': data,
          }),
        );

        if (response.statusCode == 200) {
          debugPrint(
              '[NotificationService] Notification sent to $targetUserId');
          return;
        }

        // Check for unregistered / invalid token in response body — no retry.
        final responseBody = response.data;
        if (responseBody is Map) {
          final results = responseBody['results'];
          if (results is List && results.isNotEmpty) {
            final error = results[0]['error'];
            if (error == 'NotRegistered' || error == 'InvalidRegistration') {
              debugPrint(
                  '[NotificationService] Invalid/unregistered token for '
                  '$targetUserId. Stopping.');
              return;
            }
          }
        }

        // Transient non-200 response — retry unless this was the last attempt.
        if (attempt < maxRetries) {
          debugPrint(
              '[NotificationService] Attempt ${attempt + 1} failed '
              '(status ${response.statusCode}). '
              'Retrying in ${delays[attempt]}s…');
          await Future.delayed(Duration(seconds: delays[attempt]));
        } else {
          debugPrint(
              '[NotificationService] All $maxRetries retries exhausted '
              'for $targetUserId.');
        }
      } on DioException catch (e) {
        // Requirements 2.1, 3.5, 4.5 — auth / not-found errors: stop.
        if (e.response?.statusCode == 401 ||
            e.response?.statusCode == 404) {
          debugPrint(
              '[NotificationService] Auth/unregistered error '
              '(${e.response?.statusCode}). Stopping.');
          return;
        }

        if (attempt < maxRetries) {
          debugPrint(
              '[NotificationService] DioException on attempt ${attempt + 1}: '
              '$e. Retrying in ${delays[attempt]}s…');
          await Future.delayed(Duration(seconds: delays[attempt]));
        } else {
          debugPrint(
              '[NotificationService] All retries failed for $targetUserId: $e');
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Static payload builders
  // ---------------------------------------------------------------------------

  /// Builds a notification payload for a new appointment request (to doctor).
  ///
  /// Requirement 2.2 — title and body with patient name + date.
  static Map<String, dynamic> buildAppointmentRequestPayload({
    required String patientName,
    required String appointmentDate,
  }) {
    return {
      'title': 'New Appointment Request',
      'body': '$patientName has requested an appointment on $appointmentDate.',
      'data': {'type': 'appointment_request'},
    };
  }

  /// Builds a notification payload for appointment approval (to patient).
  ///
  /// Requirement 3.2 — title and body with doctor name + date.
  static Map<String, dynamic> buildAppointmentApprovedPayload({
    required String doctorName,
    required String appointmentDate,
  }) {
    return {
      'title': 'Appointment Approved',
      'body':
          'Dr. $doctorName has approved your appointment on $appointmentDate.',
      'data': {'type': 'appointment_approved'},
    };
  }

  /// Builds a notification payload for a consultation that has started (to patient).
  ///
  /// Requirement 4.2 / 4.3 — title, body, and data payload with consultationId
  /// and roomId.
  static Map<String, dynamic> buildConsultationStartedPayload({
    required String doctorName,
    required String consultationId,
    required String roomId,
  }) {
    return {
      'title': 'Your Doctor is Ready',
      'body': 'Dr. $doctorName is ready to begin your consultation.',
      'data': {
        'type': 'consultation_started',
        'consultationId': consultationId,
        'roomId': roomId,
      },
    };
  }
}
