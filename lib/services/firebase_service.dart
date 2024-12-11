import 'package:firebase_database/firebase_database.dart';
import '../models/thought.dart';
import '../models/task_history_item.dart';
import '../models/predefined_task.dart';

class FirebaseService {
  static final _database = FirebaseDatabase.instance.ref();
  
  // Tasks
  static Future<void> syncTask(TaskHistoryItem task) async {
    await _database.child('tasks').push().set({
      'title': task.title,
      'userName': task.userName,
      'completedAt': task.completedAt.toIso8601String(),
      'userAvatar': task.userAvatar,
      'duration': task.duration?.inMinutes,
    });
  }

  // Thoughts
  static Future<void> syncThought(Thought thought) async {
    await _database.child('thoughts').push().set({
      'text': thought.text,
      'mentalLoad': thought.mentalLoad,
      'userId': thought.userId,
      'userName': thought.userName,
      'userAvatar': thought.userAvatar,
      'date': thought.date.toIso8601String(),
    });
  }

  // Notifications
  static Future<void> syncNotification(String type, {
    required String fromUser,
    required String toUser,
    String? taskTitle,
    double? mentalLoad,
  }) async {
    await _database.child('notifications').push().set({
      'type': type,
      'fromUser': fromUser,
      'toUser': toUser,
      'taskTitle': taskTitle,
      'mentalLoad': mentalLoad,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
    });
  }

  // Listen to notifications for current user
  static void listenToNotifications(String currentUserName, Function(Map<String, dynamic>) onNotification) {
    _database.child('notifications')
      .orderByChild('toUser')
      .equalTo(currentUserName)
      .onChildAdded
      .listen((event) {
        if (event.snapshot.value != null) {
          final notification = Map<String, dynamic>.from(event.snapshot.value as Map);
          if (notification['read'] == false) {
            onNotification(notification);
            // Mark as read
            event.snapshot.ref.update({'read': true});
          }
        }
      });
  }

  // Listen to all updates
  static void listenToUpdates(Function() onUpdate) {
    _database.onValue.listen((_) {
      onUpdate();
    });
  }
} 