import 'package:flutter/material.dart';
import 'dart:math';
import '../models/predefined_task.dart';

class ThankBackDialog extends StatelessWidget {
  final String personName;
  final List<PredefinedTask> availableTasks;

  const ThankBackDialog({
    super.key,
    required this.personName,
    required this.availableTasks,
  });

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final suggestedTask = availableTasks[random.nextInt(availableTasks.length)];

    return AlertDialog(
      title: const Text('Thank Back?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Would you like to thank $personName by doing a task?'),
          const SizedBox(height: 12),
          Text(
            'Suggested task: ${suggestedTask.title} (${suggestedTask.formattedEffort})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Maybe Later'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, suggestedTask),
          child: const Text('Do This Task'),
        ),
      ],
    );
  }
} 