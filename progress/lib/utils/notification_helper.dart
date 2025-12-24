import '../services/notification_service.dart';
import '../models/daily_task.dart';
import '../models/short_term_goal.dart';

class NotificationHelper {
  // Schedule daily reminders for tasks
  static Future<void> scheduleDailyTaskReminders(
    ShortTermGoal goal,
    List<DailyTask> tasks,
  ) async {
    for (final task in tasks) {
      if (task.isDaily) {
        // Schedule daily at 8 AM
        await NotificationService.instance.scheduleDailyNotification(
          id: _generateTaskId(task.id),
          title: goal.title,
          body: 'Don\'t forget: ${task.taskName}',
          hour: 8,
          minute: 0,
          payload: 'short-term-goal:${goal.id}:task:${task.id}',
        );
      } else if (task.isRecurring && task.dayOfWeek != null) {
        // Schedule weekly on specific day at 8 AM
        // Convert from 0-6 (Monday-Sunday) to 1-7 (Monday-Sunday)
        final dayOfWeek = task.dayOfWeek! + 1;
        await NotificationService.instance.scheduleWeeklyNotification(
          id: _generateTaskId(task.id),
          title: goal.title,
          body: 'Time for: ${task.taskName}',
          dayOfWeek: dayOfWeek,
          hour: 8,
          minute: 0,
          payload: 'short-term-goal:${goal.id}:task:${task.id}',
        );
      } else if (task.specificDate != null && task.specificDate!.isAfter(DateTime.now())) {
        // Schedule for specific date at 8 AM
        final scheduledDate = DateTime(
          task.specificDate!.year,
          task.specificDate!.month,
          task.specificDate!.day,
          8,
          0,
        );
        await NotificationService.instance.scheduleNotification(
          id: _generateTaskId(task.id),
          title: goal.title,
          body: 'Reminder: ${task.taskName}',
          scheduledDate: scheduledDate,
          payload: 'short-term-goal:${goal.id}:task:${task.id}',
        );
      }
    }
  }

  // Cancel reminders for a task
  static Future<void> cancelTaskReminders(DailyTask task) async {
    await NotificationService.instance.cancelNotification(_generateTaskId(task.id));
  }

  // Cancel all reminders for a goal
  static Future<void> cancelGoalReminders(ShortTermGoal goal, List<DailyTask> tasks) async {
    for (final task in tasks) {
      await cancelTaskReminders(task);
    }
  }

  // Helper to generate a consistent ID from task ID
  static int _generateTaskId(String taskId) {
    // Convert task ID to a number (using hash code)
    return taskId.hashCode.abs() % 1000000;
  }


  // Schedule a reminder for a goal due date
  static Future<void> scheduleGoalReminder(ShortTermGoal goal) async {
    if (goal.dueDate != null && goal.dueDate!.isAfter(DateTime.now())) {
      // Remind 1 day before due date
      final reminderDate = goal.dueDate!.subtract(const Duration(days: 1));
      if (reminderDate.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleNotification(
          id: _generateGoalId(goal.id),
          title: 'Goal Reminder',
          body: '${goal.title} is due tomorrow!',
          scheduledDate: reminderDate,
          payload: 'short-term-goal:${goal.id}',
        );
      }
    }
  }

  static int _generateGoalId(String goalId) {
    return goalId.hashCode.abs() % 1000000;
  }
}

