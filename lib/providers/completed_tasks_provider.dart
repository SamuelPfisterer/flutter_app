import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_history_item.dart';

final completedTasksProvider = StateNotifierProvider<CompletedTasksNotifier, List<TaskHistoryItem>>((ref) {
  return CompletedTasksNotifier();
});

class CompletedTasksNotifier extends StateNotifier<List<TaskHistoryItem>> {
  CompletedTasksNotifier() : super([
    TaskHistoryItem(
      title: 'Cleaned Living Room',
      userName: 'Franca',
      completedAt: DateTime.now().subtract(const Duration(hours: 3)),
      userAvatar: 'https://picsum.photos/200', // Random sample image
    ),
    TaskHistoryItem(
      title: 'Took Out Trash',
      userName: 'Franca',
      completedAt: DateTime.now().subtract(const Duration(hours: 6)),
      userAvatar: 'https://picsum.photos/200',
    ),
    TaskHistoryItem(
      title: 'Prepared Lunch',
      userName: 'Franca',
      completedAt: DateTime.now().subtract(const Duration(hours: 9)),
      userAvatar: 'https://picsum.photos/200',
    ),
  ]);

  void toggleThanks(int index) {
    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index)
          TaskHistoryItem(
            title: state[i].title,
            userName: state[i].userName,
            completedAt: state[i].completedAt,
            userAvatar: state[i].userAvatar,
            thanked: !state[i].thanked,
            gifted: state[i].gifted,
          )
        else
          state[i]
    ];
  }

  void toggleGift(int index) {
    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index)
          TaskHistoryItem(
            title: state[i].title,
            userName: state[i].userName,
            completedAt: state[i].completedAt,
            userAvatar: state[i].userAvatar,
            thanked: state[i].thanked,
            gifted: !state[i].gifted,
          )
        else
          state[i]
    ];
  }

  void addTask(TaskHistoryItem task) {
    state = [task, ...state];
  }
}
