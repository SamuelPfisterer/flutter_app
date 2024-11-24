import 'dart:math';
import '../models/task.dart';

class MockTaskData {
  static List<Task> generateMockTasks() {
    final now = DateTime.now();
    final random = Random();
    final currentUserId = "user1";
    final partnerId = "user2";
    
    List<Task> tasks = [];
    
    // Generate tasks for the past 4 weeks
    for (int week = 0; week < 4; week++) {
      // Generate 10-15 tasks per week
      int tasksThisWeek = random.nextInt(5) + 10;
      
      for (int i = 0; i < tasksThisWeek; i++) {
        final isUserTask = random.nextBool();
        final duration = Duration(minutes: random.nextInt(120) + 30);
        final daysAgo = week * 7 + random.nextInt(7);
        
        tasks.add(Task(
          title: 'Task ${i + 1}',
          duration: duration,
          userId: isUserTask ? currentUserId : partnerId,
          userName: isUserTask ? "You" : "Partner",
          userAvatar: isUserTask ? "avatar1.jpg" : "avatar2.jpg",
          completedAt: now.subtract(Duration(days: daysAgo)),
        ));
      }
    }
    
    return tasks;
  }
} 