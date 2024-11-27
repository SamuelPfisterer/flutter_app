import 'dart:math';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../models/predefined_task.dart';

class NotificationService {
  static final Map<String, List<PendingNotification>> _pendingNotifications = {};

  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'help_requests',
          channelName: 'Help Requests',
          channelDescription: 'Notifications for help requests',
          defaultColor: const Color(0xFF8B4513),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
      ],
    );
    
    // Request notification permissions
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) async {
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  static Future<void> storeNotification(
    String taskTitle,
    String thankedByName,
    String recipientName,
    {bool isHelpRequest = false}
  ) async {
    if (!_pendingNotifications.containsKey(recipientName)) {
      _pendingNotifications[recipientName] = [];
    }
    
    _pendingNotifications[recipientName]!.add(
      PendingNotification(
        taskTitle: taskTitle,
        thankedByName: thankedByName,
        isHelpRequest: isHelpRequest,
      ),
    );
  }

  static Future<void> checkAndShowNotifications(String userName) async {
    if (!_pendingNotifications.containsKey(userName)) return;
    
    final notifications = _pendingNotifications[userName] ?? [];
    for (final notification in notifications) {
      if (notification.isHelpRequest) {
        await sendHelpRequestNotification(
          notification.thankedByName,
        );
      } else {
        await sendThanksNotification(
          notification.taskTitle,
          notification.thankedByName,
        );
      }
    }
    
    // Clear shown notifications
    _pendingNotifications[userName]?.clear();
  }

  static Future<void> sendHelpRequestNotification(String requestedByName) async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
      return;
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 4,  // Different ID for help requests
        channelKey: 'help_requests',
        title: 'Help Needed! 🤝',
        body: '$requestedByName needs help with household tasks',
      ),
    );
  }

  static Future<void> sendThanksNotification(String taskTitle, String thankedByName) async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
      return;
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,  // Different ID from help requests
        channelKey: 'help_requests',
        title: 'Thank You! 💝',
        body: '$thankedByName thanked you for: $taskTitle',
      ),
    );
  }

  static Future<void> notifyImbalance(double difference, PredefinedTask recommendedTask) async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
      return;
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 3,
        channelKey: 'help_requests',
        title: 'Workload Imbalance! 🤝',
        body: 'Your partner is doing ${difference.round()}% more. Recommended task: ${recommendedTask.title}',
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'EXECUTE_TASK',
          label: 'Do this task',
        ),
      ],
    );
  }
}

class PendingNotification {
  final String taskTitle;
  final String thankedByName;
  final bool isHelpRequest;

  PendingNotification({
    required this.taskTitle,
    required this.thankedByName,
    this.isHelpRequest = false,
  });
} 