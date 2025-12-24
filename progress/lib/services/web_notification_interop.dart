// Web-only interop file for web notifications
// This file is conditionally imported only on web platforms

import 'dart:js_interop';

extension type WindowInterop(JSObject _) implements JSObject {
  external WebNotificationService? get webNotificationService;
}

@JS('window')
external WindowInterop get window;

extension type WebNotificationService(JSObject _) implements JSObject {
  external JSPromise<JSString> requestPermission();
  external void scheduleNotification(
    JSNumber id,
    JSString title,
    JSString body,
    JSString scheduledTime,
    JSObject? options,
  );
  external void scheduleDailyNotification(
    JSNumber id,
    JSString title,
    JSString body,
    JSNumber hour,
    JSNumber minute,
    JSObject? options,
  );
  external void scheduleWeeklyNotification(
    JSNumber id,
    JSString title,
    JSString body,
    JSNumber dayOfWeek,
    JSNumber hour,
    JSNumber minute,
    JSObject? options,
  );
  external void cancelNotification(JSNumber id);
}

WebNotificationService? getWebNotificationService() {
  return window.webNotificationService;
}

Future<String> requestWebNotificationPermission() async {
  final service = getWebNotificationService();
  if (service == null) return 'denied';
  final result = await service.requestPermission().toDart;
  return result.toDart;
}

void callScheduleNotification(int id, String title, String body, String scheduledTime, Map<String, dynamic>? options) {
  final service = getWebNotificationService();
  if (service == null) return;
  service.scheduleNotification(
    id.toJS,
    title.toJS,
    body.toJS,
    scheduledTime.toJS,
    options?.jsify() as JSObject?,
  );
}

void callScheduleDailyNotification(int id, String title, String body, int hour, int minute, Map<String, dynamic>? options) {
  final service = getWebNotificationService();
  if (service == null) return;
  service.scheduleDailyNotification(
    id.toJS,
    title.toJS,
    body.toJS,
    hour.toJS,
    minute.toJS,
    options?.jsify() as JSObject?,
  );
}

void callScheduleWeeklyNotification(int id, String title, String body, int dayOfWeek, int hour, int minute, Map<String, dynamic>? options) {
  final service = getWebNotificationService();
  if (service == null) return;
  service.scheduleWeeklyNotification(
    id.toJS,
    title.toJS,
    body.toJS,
    dayOfWeek.toJS,
    hour.toJS,
    minute.toJS,
    options?.jsify() as JSObject?,
  );
}

void callCancelNotification(int id) {
  final service = getWebNotificationService();
  if (service == null) return;
  service.cancelNotification(id.toJS);
}

