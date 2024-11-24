import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/predefined_task.dart';

final predefinedTasksProvider = StateNotifierProvider<PredefinedTasksNotifier, List<PredefinedTask>>((ref) {
  return PredefinedTasksNotifier();
});

class PredefinedTasksNotifier extends StateNotifier<List<PredefinedTask>> {
  PredefinedTasksNotifier() : super([
    PredefinedTask(
      id: '1',
      title: 'Water Plants',
      effort: const Duration(minutes: 12),
    ),
    PredefinedTask(
      id: '2',
      title: 'Clean Living Room',
      effort: const Duration(minutes: 30),
    ),
    // Add more predefined tasks...
  ]);

  void addTask(String title, Duration effort) {
    final newTask = PredefinedTask(
      id: DateTime.now().toString(),
      title: title,
      effort: effort,
    );
    state = [...state, newTask];
  }

  void removeTask(String id) {
    state = state.where((task) => task.id != id).toList();
  }

  void updateTask(String id, String title, Duration effort) {
    state = [
      for (final task in state)
        if (task.id == id)
          PredefinedTask(id: id, title: title, effort: effort)
        else
          task
    ];
  }
} 