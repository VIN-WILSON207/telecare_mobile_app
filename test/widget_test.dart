// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:telecare_mobile_app/core/services/notification_service.dart';
import 'package:telecare_mobile_app/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    final notificationService = NotificationService(
      localNotifications: FlutterLocalNotificationsPlugin(),
      messaging: FirebaseMessaging.instance,
      firestore: FirebaseFirestore.instance,
      dio: Dio(),
      fcmServerKey: 'test',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: const [],
        child: TeleCareApp(notificationService: notificationService),
      ),
    );

    await tester.pumpAndSettle();
  });
}

