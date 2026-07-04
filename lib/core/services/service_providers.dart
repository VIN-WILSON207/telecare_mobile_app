import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'fcm_service.dart';
import 'notification_service.dart';

/// Provides the singleton [FcmService] instance.
/// 
/// Overridden in main.dart via ProviderScope.overrides.
final fcmServiceProvider = Provider<FcmService>((ref) {
  throw UnimplementedError('fcmServiceProvider must be overridden in main.dart');
});

/// Provides the singleton [NotificationService] instance.
/// 
/// Overridden in main.dart via ProviderScope.overrides.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('notificationServiceProvider must be overridden in main.dart');
});

/// Provides a singleton [Dio] instance for HTTP requests.
final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

/// Provides a singleton [FlutterLocalNotificationsPlugin] instance.
final localNotificationsProvider = Provider<FlutterLocalNotificationsPlugin>((ref) {
  return FlutterLocalNotificationsPlugin();
});
