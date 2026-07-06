import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'notification_service.dart';

/// Provides the singleton [NotificationService] instance.
///
/// Overridden in main.dart via ProviderScope.overrides.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError(
    'notificationServiceProvider must be overridden in main.dart',
  );
});

/// Provides a singleton [Dio] instance for HTTP requests.
final dioProvider = Provider<Dio>((ref) {
  return Dio();
});
