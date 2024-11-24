import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_history_item.dart';
import '../models/predefined_task.dart';
import '../providers/current_user_provider.dart';
import 'dart:math';

final taskHistoryProvider = StateNotifierProvider<TaskHistoryNotifier, List<TaskHistoryItem>>((ref) {
  return TaskHistoryNotifier();
});

class TaskHistoryNotifier extends StateNotifier<List<TaskHistoryItem>> {
  TaskHistoryNotifier() : super(_generateInitialTasks());

  void addTask(TaskHistoryItem task) {
    state = [task, ...state];
  }

  void removeTask(TaskHistoryItem task) {
    state = state.where((t) => t != task).toList();
  }

  void update(List<TaskHistoryItem> Function(List<TaskHistoryItem>) callback) {
    state = callback(state);
  }
}

List<TaskHistoryItem> _generateInitialTasks() {
  final random = Random();
  final now = DateTime.now();
  
  final predefinedTasks = [
    PredefinedTask(id: '1', title: 'Water Plants', effort: const Duration(minutes: 12)),
    PredefinedTask(id: '2', title: 'Clean Living Room', effort: const Duration(minutes: 30)),
    PredefinedTask(id: '3', title: 'Do Laundry', effort: const Duration(minutes: 45)),
    PredefinedTask(id: '4', title: 'Cook Dinner', effort: const Duration(minutes: 60)),
    PredefinedTask(id: '5', title: 'Take Out Trash', effort: const Duration(minutes: 5)),
  ];

  final franca = users[0];  // Franca
  final christian = users[1];  // Christian

  List<TaskHistoryItem> tasks = [];
  
  // Generate 4 weeks of history
  for (int day = 28; day >= 0; day--) {
    final date = now.subtract(Duration(days: day));
    final isWeekend = date.weekday >= 6;
    final tasksPerDay = isWeekend ? random.nextInt(3) + 4 : random.nextInt(2) + 2;
    
    for (int i = 0; i < tasksPerDay; i++) {
      final task = predefinedTasks[random.nextInt(predefinedTasks.length)];
      final isFranca = random.nextDouble() > 0.45; // Slight imbalance
      final user = isFranca ? franca : christian;
      
      tasks.add(TaskHistoryItem(
        title: task.title,
        userName: user.name,
        completedAt: DateTime(
          date.year, date.month, date.day,
          9 + random.nextInt(12), // Between 9 AM and 9 PM
          random.nextInt(60),
        ),
        userAvatar: user.avatarUrl,
        duration: task.effort,
      ));
    }
  }
  
  return tasks..sort((a, b) => b.completedAt.compareTo(a.completedAt));
} 