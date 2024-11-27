import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/task_history_provider.dart';
import '../providers/current_user_provider.dart';
import '../providers/predefined_tasks_provider.dart';
import '../providers/thoughts_provider.dart';
import '../models/distribution.dart';
import '../models/task_history_item.dart';
import '../models/predefined_task.dart';
import '../models/thought.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../utils/mock_data.dart';

enum DistributionTimeFrame { daily, weekly, monthly }
enum TimeFrame { weekly, monthly }

// Move _DataPoints class to top level
class _DataPoints {
  final List<FlSpot> real;
  final List<FlSpot> predicted;
  final List<FlSpot> partner;
  final List<FlSpot> partnerPredicted;
  
  _DataPoints(this.real, this.predicted, this.partner, this.partnerPredicted);
}

class DistributionScreen extends ConsumerStatefulWidget {
  const DistributionScreen({super.key});

  @override
  ConsumerState<DistributionScreen> createState() => _DistributionScreenState();
}

class _DistributionScreenState extends ConsumerState<DistributionScreen> {
  DistributionTimeFrame _timeFrame = DistributionTimeFrame.daily;
  bool _showStats = false;  // Toggle between distribution and stats
  TimeFrame _selectedTimeFrame = TimeFrame.weekly;  // For stats view
  int _weekOffset = 0;  // For stats week navigation
  List<Thought> _thoughts = [];  // Define thoughts list

  @override
  void initState() {
    super.initState();
    // Initialize with mock data
    _thoughts = MockData.generateMockThoughts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Mental Load'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // View toggle
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Distribution'),
                  icon: Icon(Icons.pie_chart),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Stats'),
                  icon: Icon(Icons.analytics),
                ),
              ],
              selected: {_showStats},
              onSelectionChanged: (Set<bool> selected) {
                setState(() {
                  _showStats = selected.first;
                });
              },
            ),
          ),
          // Content based on toggle
          Expanded(
            child: _showStats ? buildStatsContent() : buildDistributionContent(),
          ),
        ],
      ),
    );
  }

  Widget buildStatsContent() {
    final thoughts = ref.watch(thoughtsProvider);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Time frame selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: TimeFrame.values.map((timeFrame) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilterChip(
                    label: Text(timeFrame.toString().split('.').last),
                    selected: _selectedTimeFrame == timeFrame,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTimeFrame = timeFrame;
                        _weekOffset = 0;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedTimeFrame == TimeFrame.weekly) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _weekOffset--;
                    });
                  },
                ),
                Text(
                  _weekOffset == 0
                      ? 'This Week'
                      : _weekOffset == -1
                          ? 'Last Week'
                          : '${_weekOffset.abs()} Weeks Ago',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _weekOffset < 0
                      ? () {
                          setState(() {
                            _weekOffset++;
                          });
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: thoughts.isEmpty
                ? const Center(child: Text('No thoughts yet'))
                : buildThoughtsChart(thoughts),
          ),
        ],
      ),
    );
  }

  Widget buildDistributionContent() {
    final tasks = ref.watch(taskHistoryProvider);
    final currentUser = ref.watch(currentUserProvider);
    final predefinedTasks = ref.watch(predefinedTasksProvider);
    
    final distribution = _calculateDistribution(tasks, currentUser.name);
    final message = _generateMessage(distribution);
    final isImbalanced = (distribution.partnerPercentage - distribution.userPercentage).abs() > 10;
    
    final recommendedTask = isImbalanced && distribution.userPercentage < distribution.partnerPercentage
        ? _getRecommendedTask(predefinedTasks)
        : null;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Original distribution content...
            // Copy the existing content from the current build method here
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

  // Add chart building methods
  Widget buildThoughtsChart(List<Thought> thoughts) {
    final currentUser = ref.watch(currentUserProvider);
    final now = DateTime.now();
    
    // Configure time frame settings
    final (period, format, minX, maxX, xInterval) = switch (_selectedTimeFrame) {
      TimeFrame.weekly => (
        Duration(days: 1),
        'E',               // Day format (Mon, Tue, etc.)
        -6.0,             // 6 days back + today
        0.0,              // Today
        1.0,              // Show every day
      ),
      TimeFrame.monthly => (
        Duration(days: 7),  // Weekly period
        'w',               // Week format
        -3.0,             // 3 weeks back + current week
        0.0,              // Current week
        1.0,              // Show every week
      ),
    };

    // Adjust the date range based on week offset for weekly view
    final adjustedNow = _selectedTimeFrame == TimeFrame.weekly
        ? now.add(Duration(days: _weekOffset * 7))
        : now;
    
    // Add mock data if thoughts list is empty
    if (thoughts.isEmpty) {
      thoughts = MockData.generateMockThoughts();
    }

    // Group and calculate data points
    final spots = _calculateDataPoints(
      thoughts,
      currentUser.id,
      period,
      minX,
      maxX,
    );

    // Calculate maximum Y value from all data points
    double maxY = 0;
    final allSpots = [
      ...spots.real,
      ...spots.partner,
    ];
    for (var spot in allSpots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    // Add 20% padding to the max Y value and round up to nearest 5
    maxY = (maxY * 1.2).roundToDouble();
    if (maxY % 5 != 0) {
      maxY = (maxY / 5).ceil() * 5;
    }
    maxY = maxY == 0 ? 10 : maxY;

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: xInterval,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  final date = adjustedNow.add(Duration(
                    days: value.toInt(),
                  ));
                  
                  // Format based on time frame
                  final text = switch (_selectedTimeFrame) {
                    TimeFrame.weekly => value == 0 
                      ? 'Today'
                      : value == -1
                        ? 'Yesterday'
                        : DateFormat('E').format(date),
                    TimeFrame.monthly => value == 0 
                      ? 'This week' 
                      : value == -1 
                        ? 'Last week'
                        : value == -2
                          ? '2 weeks ago'
                          : '3 weeks ago',
                  };
                  
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxY <= 20 ? 2 : 5,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString());
                },
                reservedSize: 30,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          minX: minX,
          maxX: maxX,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots.real,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              dotData: FlDotData(show: true),
            ),
            LineChartBarData(
              spots: spots.predicted,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              dotData: FlDotData(show: false),
              dashArray: [5, 5],
            ),
            LineChartBarData(
              spots: spots.partner,
              isCurved: true,
              color: Colors.blue,
              dotData: FlDotData(show: true),
            ),
            LineChartBarData(
              spots: spots.partnerPredicted,
              isCurved: true,
              color: Colors.blue,
              dotData: FlDotData(show: false),
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }

  _DataPoints _calculateDataPoints(
    List<Thought> thoughts,
    String userId,
    Duration period,
    double minX,
    double maxX,
  ) {
    final now = DateTime.now();
    // Adjust the reference date based on week offset for weekly view
    final referenceDate = _selectedTimeFrame == TimeFrame.weekly
        ? now.add(Duration(days: _weekOffset * 7))
        : now;
        
    final Map<double, List<double>> realPoints = {};
    final Map<double, List<double>> partnerPoints = {};

    // Initialize maps with empty lists for all x values
    for (double x = minX; x <= maxX; x += 1) {
      realPoints[x] = [];
      partnerPoints[x] = [];
    }

    // Group thoughts by time period
    for (final thought in thoughts) {
      final difference = thought.date.difference(referenceDate);
      double x = 0;
      
      if (_selectedTimeFrame == TimeFrame.monthly) {
        x = difference.inDays / 7;   // Weekly points for monthly view
      } else {
        x = difference.inDays.toDouble();  // Daily points for weekly view
      }
      
      if (x >= minX && x <= maxX) {
        if (thought.userId == userId) {
          realPoints[x.roundToDouble()]?.add(thought.mentalLoad);
        } else {
          partnerPoints[x.roundToDouble()]?.add(thought.mentalLoad);
        }
      }
    }

    // Calculate cumulative load and create spots
    List<FlSpot> realSpots = [];
    List<FlSpot> partnerSpots = [];
    List<FlSpot> predictedSpots = [];

    // Helper function to get last known value
    double getLastKnownValue(List<FlSpot> spots) {
      return spots.isEmpty ? 0 : spots.last.y;
    }

    // Process real points - use sum instead of average
    for (final entry in realPoints.entries.where((e) => e.key <= 0)) {
      if (entry.value.isNotEmpty) {
        final totalLoad = entry.value.reduce((a, b) => a + b);
        realSpots.add(FlSpot(entry.key, totalLoad));
      } else if (realSpots.isNotEmpty) {
        realSpots.add(FlSpot(entry.key, getLastKnownValue(realSpots)));
      }
    }

    // Process partner points - use sum instead of average
    for (final entry in partnerPoints.entries.where((e) => e.key <= 0)) {
      if (entry.value.isNotEmpty) {
        final totalLoad = entry.value.reduce((a, b) => a + b);
        partnerSpots.add(FlSpot(entry.key, totalLoad));
      } else if (partnerSpots.isNotEmpty) {
        partnerSpots.add(FlSpot(entry.key, getLastKnownValue(partnerSpots)));
      }
    }

    // Sort spots by x value
    realSpots.sort((a, b) => a.x.compareTo(b.x));
    partnerSpots.sort((a, b) => a.x.compareTo(b.x));

    // Calculate predictions
    if (realSpots.isNotEmpty) {
      final lastValue = realSpots.last.y;
      final trend = realSpots.length > 1 
          ? (realSpots.last.y - realSpots[realSpots.length - 2].y)
          : 0.0;
      
      predictedSpots = [
        FlSpot(0, lastValue),
        FlSpot(maxX, lastValue + (trend * maxX)),
      ];
    }

    // Calculate partner prediction
    List<FlSpot> partnerPredictedSpots = [];
    if (partnerSpots.isNotEmpty) {
      final lastValue = partnerSpots.last.y;
      final trend = partnerSpots.length > 1 
          ? (partnerSpots.last.y - partnerSpots[partnerSpots.length - 2].y)
          : 0.0;
      
      partnerPredictedSpots = [
        FlSpot(0, lastValue),
        FlSpot(maxX, lastValue + (trend * maxX)),
      ];
    }

    return _DataPoints(
      realSpots,
      predictedSpots,
      partnerSpots,
      partnerPredictedSpots,
    );
  }
}
