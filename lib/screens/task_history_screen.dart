import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_history_item.dart';
import '../providers/task_history_provider.dart';
import '../widgets/task_selection_dialog.dart';
import '../models/predefined_task.dart';
import '../services/notification_service.dart';
import '../providers/predefined_tasks_provider.dart';
import '../models/user.dart';
import '../providers/current_user_provider.dart';
import '../widgets/thank_back_dialog.dart';
import '../theme/app_theme.dart';
import '../utils/task_utils.dart';

class TaskHistoryScreen extends ConsumerWidget {
  const TaskHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Task History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<User>(
            icon: CircleAvatar(
              backgroundImage: NetworkImage(ref.watch(currentUserProvider).avatarUrl),
              radius: 16,
            ),
            onSelected: (User user) async {
              ref.read(currentUserProvider.notifier).state = user;
              await NotificationService.checkAndShowNotifications(user.name);
            },
            itemBuilder: (BuildContext context) {
              return users.map((User user) {
                return PopupMenuItem<User>(
                  value: user,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(user.avatarUrl),
                        radius: 12,
                      ),
                      const SizedBox(width: 8),
                      Text(user.name),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final tasks = ref.read(predefinedTasksProvider);
                await NotificationService.requestHelp(tasks);
              },
              icon: const Icon(Icons.favorite),
              label: const Text('Ask Partner for Help'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskHistoryCard(task: task, index: index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final selectedTask = await showDialog<PredefinedTask>(
            context: context,
            builder: (context) => const TaskSelectionDialog(),
          );
          
          if (selectedTask != null) {
            final currentUser = ref.read(currentUserProvider);
            ref.read(taskHistoryProvider.notifier).addTask(
              TaskHistoryItem(
                title: selectedTask.title,
                userName: currentUser.name,
                completedAt: DateTime.now(),
                userAvatar: currentUser.avatarUrl,
                duration: selectedTask.effort,
              ),
            );
          }
        },
        label: const Text('Execute Task'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class TaskHistoryCard extends ConsumerWidget {
  final TaskHistoryItem task;
  final int index;
  final bool isHighPriority;

  const TaskHistoryCard({
    super.key,
    required this.task,
    required this.index,
    this.isHighPriority = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMyTask = task.userName == ref.watch(currentUserProvider).name;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isHighPriority 
          ? AppColors.userColor.withOpacity(0.2)
          : Theme.of(context).colorScheme.surface,
      elevation: isHighPriority ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isHighPriority 
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.withOpacity(0.2),
          width: isHighPriority ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(task.userAvatar),
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${isMyTask ? 'Me' : task.userName} ${_formatTime(task.completedAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMyTask)
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ActionButton(
                    label: 'Thanks',
                    onPressed: task.thanked 
                        ? null 
                        : () async {
                            final currentUser = ref.read(currentUserProvider);
                            
                            // Store the notification for the recipient
                            await NotificationService.storeNotification(
                              task.title,
                              currentUser.name,
                              task.userName  // recipient
                            );

                            final suggestedTask = await showDialog<PredefinedTask>(
                              context: context,
                              builder: (context) => ThankBackDialog(
                                personName: task.userName,
                                availableTasks: ref.read(predefinedTasksProvider),
                              ),
                            );

                            if (suggestedTask != null) {
                              final currentUser = ref.read(currentUserProvider);
                              ref.read(taskHistoryProvider.notifier).addTask(
                                TaskHistoryItem(
                                  title: suggestedTask.title,
                                  userName: currentUser.name,
                                  completedAt: DateTime.now(),
                                  userAvatar: currentUser.avatarUrl,
                                  duration: suggestedTask.effort,
                                ),
                              );
                            }

                            ref.read(taskHistoryProvider.notifier).update((state) {
                              final newState = List<TaskHistoryItem>.from(state);
                              newState[index] = TaskHistoryItem(
                                title: task.title,
                                userName: task.userName,
                                completedAt: task.completedAt,
                                userAvatar: task.userAvatar,
                                duration: task.duration,
                                thanked: true,
                                gifted: task.gifted,
                              );
                              return newState;
                            });
                          },
                    active: task.thanked,
                  ),
                  const SizedBox(height: 8),
                  ActionButton(
                    label: 'Gift',
                    onPressed: () => ref.read(taskHistoryProvider.notifier).update((state) {
                      final newState = List<TaskHistoryItem>.from(state);
                      newState[index] = TaskHistoryItem(
                        title: task.title,
                        userName: task.userName,
                        completedAt: task.completedAt,
                        userAvatar: task.userAvatar,
                        duration: task.duration,
                        thanked: task.thanked,
                        gifted: !task.gifted,
                      );
                      return newState;
                    }),
                    active: task.gifted,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return 'at ${DateFormat('h:mm a').format(time)} today';
    } else if (difference.inDays == 1) {
      return 'at ${DateFormat('h:mm a').format(time)} yesterday';
    } else if (difference.inDays < 7) {
      return 'at ${DateFormat('h:mm a').format(time)} on ${DateFormat('EEEE').format(time)}';
    } else {
      return 'at ${DateFormat('h:mm a').format(time)} on ${DateFormat('MMM d').format(time)}';
    }
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool active;

  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    
    return SizedBox(
      width: 80,
      height: 24,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: isDisabled
              ? Colors.grey.withOpacity(0.1)
              : active 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDisabled
                  ? Colors.grey.withOpacity(0.3)
                  : active 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.withOpacity(0.3),
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDisabled
                ? Colors.grey.withOpacity(0.5)
                : active 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}