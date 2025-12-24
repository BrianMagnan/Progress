// Web Notification Service for Flutter Web
// This file handles browser notifications

class WebNotificationService {
  constructor() {
    this.permission = 'default';
    this.scheduledNotifications = new Map();
    this.checkPermission();
  }

  checkPermission() {
    if ('Notification' in window) {
      this.permission = Notification.permission;
    }
  }

  async requestPermission() {
    if (!('Notification' in window)) {
      console.error('This browser does not support notifications');
      return 'denied';
    }

    if (this.permission === 'granted') {
      return 'granted';
    }

    if (this.permission === 'denied') {
      return 'denied';
    }

    try {
      const permission = await Notification.requestPermission();
      this.permission = permission;
      return permission;
    } catch (error) {
      console.error('Error requesting notification permission:', error);
      return 'denied';
    }
  }

  showNotification(title, body, options = {}) {
    if (this.permission !== 'granted') {
      console.warn('Notification permission not granted');
      return null;
    }

    const notificationOptions = {
      body: body,
      icon: options.icon || '/icons/Icon-192.png',
      badge: options.badge || '/icons/Icon-192.png',
      tag: options.tag,
      requireInteraction: options.requireInteraction || false,
      ...options
    };

    try {
      const notification = new Notification(title, notificationOptions);
      
      if (options.onClick) {
        notification.onclick = options.onClick;
      }

      // Auto-close after 5 seconds if not requiring interaction
      if (!notificationOptions.requireInteraction) {
        setTimeout(() => {
          notification.close();
        }, 5000);
      }

      return notification;
    } catch (error) {
      console.error('Error showing notification:', error);
      return null;
    }
  }

  scheduleNotification(id, title, body, scheduledTime, options = {}) {
    const now = new Date().getTime();
    const scheduled = new Date(scheduledTime).getTime();
    const delay = scheduled - now;

    if (delay < 0) {
      console.warn('Scheduled time is in the past');
      return;
    }

    // Cancel existing notification with same ID
    this.cancelNotification(id);

    const timeoutId = setTimeout(() => {
      this.showNotification(title, body, {
        ...options,
        tag: `notification-${id}`,
        onClick: () => {
          window.focus();
          if (options.onClick) {
            options.onClick();
          }
        }
      });
      this.scheduledNotifications.delete(id);
    }, delay);

    this.scheduledNotifications.set(id, timeoutId);
  }

  scheduleDailyNotification(id, title, body, hour, minute, options = {}) {
    const now = new Date();
    let scheduled = new Date();
    scheduled.setHours(hour, minute, 0, 0);

    // If time has passed today, schedule for tomorrow
    if (scheduled.getTime() < now.getTime()) {
      scheduled.setDate(scheduled.getDate() + 1);
    }

    // Schedule the first occurrence
    this.scheduleNotification(id, title, body, scheduled.toISOString(), options);

    // Set up daily recurrence
    const scheduleNext = () => {
      scheduled.setDate(scheduled.getDate() + 1);
      this.scheduleNotification(id, title, body, scheduled.toISOString(), options);
    };

    // Calculate time until next day at the specified time
    const timeUntilNext = scheduled.getTime() - now.getTime();
    setTimeout(() => {
      scheduleNext();
      // Schedule every 24 hours
      setInterval(scheduleNext, 24 * 60 * 60 * 1000);
    }, timeUntilNext);
  }

  scheduleWeeklyNotification(id, title, body, dayOfWeek, hour, minute, options = {}) {
    const now = new Date();
    let scheduled = new Date();
    scheduled.setHours(hour, minute, 0, 0);

    // Calculate days until target weekday (1 = Monday, 7 = Sunday)
    const currentDay = now.getDay(); // 0 = Sunday, 6 = Saturday
    const targetDay = dayOfWeek === 7 ? 0 : dayOfWeek; // Convert to 0-6 format
    
    let daysUntil = (targetDay - currentDay + 7) % 7;
    if (daysUntil === 0 && scheduled.getTime() < now.getTime()) {
      daysUntil = 7; // If it's today but time passed, schedule for next week
    }

    scheduled.setDate(scheduled.getDate() + daysUntil);

    // Schedule the first occurrence
    this.scheduleNotification(id, title, body, scheduled.toISOString(), options);

    // Set up weekly recurrence
    const scheduleNext = () => {
      scheduled.setDate(scheduled.getDate() + 7);
      this.scheduleNotification(id, title, body, scheduled.toISOString(), options);
    };

    const timeUntilNext = scheduled.getTime() - now.getTime();
    setTimeout(() => {
      scheduleNext();
      // Schedule every 7 days
      setInterval(scheduleNext, 7 * 24 * 60 * 60 * 1000);
    }, timeUntilNext);
  }

  cancelNotification(id) {
    const timeoutId = this.scheduledNotifications.get(id);
    if (timeoutId) {
      clearTimeout(timeoutId);
      this.scheduledNotifications.delete(id);
    }
  }

  cancelAllNotifications() {
    this.scheduledNotifications.forEach((timeoutId) => {
      clearTimeout(timeoutId);
    });
    this.scheduledNotifications.clear();
  }
}

// Create global instance
window.webNotificationService = new WebNotificationService();

