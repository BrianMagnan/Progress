// Stub file for non-web platforms
// This file provides null implementations for web notification interop

dynamic getWebNotificationService() => null;
Future<String> requestWebNotificationPermission() async => 'denied';
void callScheduleNotification(int id, String title, String body, String scheduledTime, Map<String, dynamic>? options) {}
void callScheduleDailyNotification(int id, String title, String body, int hour, int minute, Map<String, dynamic>? options) {}
void callScheduleWeeklyNotification(int id, String title, String body, int dayOfWeek, int hour, int minute, Map<String, dynamic>? options) {}
void callCancelNotification(int id) {}

