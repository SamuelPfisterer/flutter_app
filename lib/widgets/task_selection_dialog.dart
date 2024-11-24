import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/predefined_tasks_provider.dart';
import '../models/predefined_task.dart';
import '../screens/task_management_screen.dart';

class TaskSelectionDialog extends ConsumerWidget {
  const TaskSelectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(predefinedTasksProvider);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Task',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return ListTile(
                    title: Text(task.title),
                    trailing: Text(task.formattedEffort),
                    onTap: () {
                      Navigator.of(context).pop(task);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Show task management screen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const TaskManagementScreen(),
                  ),
                );
              },
              child: const Text('Manage Tasks'),
            ),
          ],
        ),
      ),
    );
  }
} 