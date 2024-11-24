import '../models/predefined_task.dart';

class TaskUtils {
  static PredefinedTask? getRecommendedTask(List<PredefinedTask> tasks) {
    if (tasks.isEmpty) return null;
    
    // Sort by effort and return highest priority task
    final sortedTasks = List<PredefinedTask>.from(tasks)
      ..sort((a, b) => b.effort.compareTo(a.effort));
    return sortedTasks.first;
  }
} 