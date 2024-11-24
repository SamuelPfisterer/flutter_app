import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/task_history_provider.dart';
import '../providers/current_user_provider.dart';
import '../providers/predefined_tasks_provider.dart';
import '../models/distribution.dart';
import '../models/task_history_item.dart';
import '../models/predefined_task.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

enum DistributionTimeFrame { daily, weekly, monthly }

class DistributionScreen extends ConsumerStatefulWidget {
  const DistributionScreen({super.key});

  @override
  ConsumerState<DistributionScreen> createState() => _DistributionScreenState();
}

class _DistributionScreenState extends ConsumerState<DistributionScreen> {
  DistributionTimeFrame _timeFrame = DistributionTimeFrame.daily;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskHistoryProvider);
    final currentUser = ref.watch(currentUserProvider);
    final predefinedTasks = ref.watch(predefinedTasksProvider);
    
    final distribution = _calculateDistribution(tasks, currentUser.name);
    final message = _generateMessage(distribution);
    final isImbalanced = (distribution.partnerPercentage - distribution.userPercentage).abs() > 10;
    
    // Get recommended task if imbalanced
    final recommendedTask = isImbalanced && distribution.userPercentage < distribution.partnerPercentage
        ? _getRecommendedTask(predefinedTasks)
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Distribution'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Time frame selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: DistributionTimeFrame.values.map((frame) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _timeFrame = frame;
                    });
                  },
                  child: Column(
                    children: [
                      Text(
                        frame.toString().split('.').last,
                        style: TextStyle(
                          color: _timeFrame == frame ? 
                            Theme.of(context).colorScheme.primary : 
                            Colors.grey,
                        ),
                      ),
                      if (_timeFrame == frame)
                        Container(
                          height: 2,
                          width: 60,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Message card
            Card(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      'You are getting there!',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Donut chart
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: distribution.partnerPercentage,
                      title: '${distribution.partnerPercentage.round()}%',
                      color: AppColors.partnerColor,
                      radius: 100,
                    ),
                    PieChartSectionData(
                      value: distribution.userPercentage,
                      title: '${distribution.userPercentage.round()}%',
                      color: AppColors.userColor,
                      radius: 100,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            
            // Legend
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildLegendItem(
                    'Partner did ${distribution.partnerPercentage.round()}% of the work (${_formatDuration(distribution.partnerDuration)})',
                    AppColors.partnerColor,
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(
                    'You did ${distribution.userPercentage.round()}% of the work (${_formatDuration(distribution.userDuration)})',
                    AppColors.userColor,
                  ),
                ],
              ),
            ),
            
            if (isImbalanced && distribution.userPercentage < distribution.partnerPercentage) ...[
              const SizedBox(height: 24),
              Card(
                color: AppColors.userColor.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Recommended Task to Balance Workload:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(recommendedTask?.title ?? 'No task available'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: recommendedTask == null ? null : () => _executeTask(context, recommendedTask),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Execute Task'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // Helper methods...

  Distribution _calculateDistribution(List<TaskHistoryItem> tasks, String userName) {
    final filteredTasks = tasks.where((task) {
      final now = DateTime.now();
      switch (_timeFrame) {
        case DistributionTimeFrame.daily:
          return task.completedAt.isAfter(DateTime(now.year, now.month, now.day));
        case DistributionTimeFrame.weekly:
          return task.completedAt.isAfter(now.subtract(const Duration(days: 7)));
        case DistributionTimeFrame.monthly:
          return task.completedAt.isAfter(now.subtract(const Duration(days: 30)));
      }
    }).toList();

    final userDuration = filteredTasks
        .where((task) => task.userName == userName)
        .fold(Duration.zero, (prev, task) => prev + task.duration);

    final partnerDuration = filteredTasks
        .where((task) => task.userName != userName)
        .fold(Duration.zero, (prev, task) => prev + task.duration);

    final totalMinutes = userDuration.inMinutes + partnerDuration.inMinutes;
    
    final distribution = Distribution(
      userPercentage: totalMinutes == 0 ? 0 : (userDuration.inMinutes / totalMinutes) * 100,
      partnerPercentage: totalMinutes == 0 ? 0 : (partnerDuration.inMinutes / totalMinutes) * 100,
      userDuration: userDuration,
      partnerDuration: partnerDuration,
    );

    return distribution;
  }

  String _generateMessage(Distribution distribution) {
    final difference = (distribution.partnerPercentage - distribution.userPercentage).abs();
    
    if (difference <= 10) {
      return 'Great job! The workload is well balanced between you and your partner!';
    } else if (distribution.userPercentage > distribution.partnerPercentage) {
      return 'Today you are contributing ${difference.round()}% more than typically last week! Do another improvement like this and your partner will be happy!';
    } else {
      return 'Your partner is contributing more. Maybe you can help with some tasks?';
    }
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours${minutes > 0 ? 'h and $minutes min' : 'h'}';
    }
    return '$minutes min';
  }

  PredefinedTask? _getRecommendedTask(List<PredefinedTask> tasks) {
    if (tasks.isEmpty) return null;
    
    // Sort by effort and return highest priority task
    final sortedTasks = List<PredefinedTask>.from(tasks)
      ..sort((a, b) => b.effort.compareTo(a.effort));
    return sortedTasks.first;
  }

  Future<void> _executeTask(BuildContext context, PredefinedTask task) async {
    final currentUser = ref.read(currentUserProvider);
    
    // Add task to history
    ref.read(taskHistoryProvider.notifier).addTask(
      TaskHistoryItem(
        title: task.title,
        userName: currentUser.name,
        completedAt: DateTime.now(),
        userAvatar: currentUser.avatarUrl,
        duration: task.effort,
      ),
    );

    // Navigate to task history screen with highlighted task
    Navigator.pushNamed(
      context, 
      '/tasks',
      arguments: {'highlightedTaskId': task.id},
    );
  }
}
