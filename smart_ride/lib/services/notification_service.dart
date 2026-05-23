// NotificationService
//
// Delivers notifications through Laravel DB polling — no Firebase required.
//
// How it works:
//   1. The Laravel backend writes a row to the `notifications` table whenever
//      a trip or booking event occurs (booking created/accepted/rejected,
//      trip started/cancelled/completed, driver rated, etc.).
//   2. The Flutter app polls GET /api/notifications every 30 seconds via
//      NotificationController, which is a GetX controller kept alive for
//      the duration of the user session.
//   3. The unread count badge on the notification bell updates reactively
//      via GetX Rx variables whenever the poll returns new data.
//
// No google-services.json, GoogleService-Info.plist, or FlutterFire CLI
// setup is required.
//
// This file is intentionally a no-op stub — all logic lives in
// NotificationController (lib/controllers/notification_controller.dart).

// ignore_for_file: unused_import
