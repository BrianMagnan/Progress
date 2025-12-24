# Local Notifications Setup

## Overview

This app uses **local notifications** (no Firebase account required!). Notifications are scheduled directly on your device and work completely offline.

## Features

- ✅ **No account required** - Works entirely on your device
- ✅ **Daily task reminders** - Get notified about your daily tasks
- ✅ **Weekly recurring reminders** - For tasks that repeat on specific days
- ✅ **Goal due date reminders** - Get notified before goals are due
- ✅ **Works offline** - No internet connection needed

## How It Works

1. **Automatic Scheduling**: When you create daily tasks, the app automatically schedules notifications
2. **Permission Request**: On first launch, the app will ask for notification permission (iOS/Android)
3. **Device-Based**: All notifications are stored and managed on your device

## Testing Notifications

### On Android:
- Notifications work on physical devices and emulators (Android 8.0+)
- Make sure to grant notification permissions when prompted

### On iOS:
- Notifications work on physical devices and simulators
- Make sure to grant notification permissions when prompted
- You may need to enable notifications in Settings → [Your App] → Notifications

## Usage

The notification system is automatically integrated with:
- **Daily Tasks**: Tasks marked as "daily" will send a reminder every day at 8 AM
- **Weekly Tasks**: Tasks scheduled for specific days will send reminders on those days at 8 AM
- **Goal Due Dates**: Goals with due dates will send a reminder 1 day before

## Customization

You can customize notification times by modifying the `NotificationHelper` class in `lib/utils/notification_helper.dart`.

## Troubleshooting

**Notifications not appearing?**
1. Check that notification permissions are granted in device settings
2. Make sure the device time is set correctly
3. For iOS, check Settings → [Your App] → Notifications

**Notifications appearing at wrong time?**
- Make sure your device timezone is set correctly
- The app uses your device's local timezone

