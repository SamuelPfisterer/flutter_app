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
  bool _showStats = false;
  TimeFrame _selectedTimeFrame = TimeFrame.weekly;
  int _weekOffset = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Distribution'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Time'),
                  icon: Icon(Icons.timer),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Mental Load'),
                  icon: Icon(Icons.psychology),
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
                : Column(
                    children: [
                      Expanded(child: buildThoughtsChart(thoughts)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          children: [
                            _buildLegendItem(
                              'Your mental load',
                              AppColors.userColor,
                              isDashed: false,
                            ),
                            const SizedBox(height: 8),
                            _buildLegendItem(
                              'Partner\'s mental load',
                              AppColors.partnerColor,
                              isDashed: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                        icon: const Icon(Icons.add_task),
                        label: const Text('Complete Task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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

  Widget buildThoughtsChart(List<Thought> thoughts) {
    final currentUser = ref.watch(currentUserProvider);
    final now = DateTime.now();
    
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

    final adjustedNow = _selectedTimeFrame == TimeFrame.weekly
        ? now.add(Duration(days: _weekOffset * 7))
        : now;
    
    if (thoughts.isEmpty) {
      thoughts = MockData.generateMockThoughts();
    }

    final spots = _calculateDataPoints(
      thoughts,
      currentUser.id,
      period,
      minX,
      maxX,
    );

    double maxY = 0;
    for (var spot in [...spots.real, ...spots.partner]) {
      if (spot.y > maxY) maxY = spot.y;
    }
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
              color: AppColors.userColor,
              dotData: FlDotData(show: true),
            ),
            LineChartBarData(
              spots: spots.predicted,
              isCurved: true,
              color: AppColors.userColor,
              dotData: FlDotData(show: false),
              dashArray: [5, 5],
            ),
            LineChartBarData(
              spots: spots.partner,
              isCurved: true,
              color: AppColors.partnerColor,
              dotData: FlDotData(show: true),
            ),
            LineChartBarData(
              spots: spots.partnerPredicted,
              isCurved: true,
              color: AppColors.partnerColor,
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
    final referenceDate = _selectedTimeFrame == TimeFrame.weekly
        ? now.add(Duration(days: _weekOffset * 7))
        : now;
        
    final Map<double, List<double>> realPoints = {};
    final Map<double, List<double>> partnerPoints = {};

    for (double x = minX; x <= maxX; x += 1) {
      realPoints[x] = [];
      partnerPoints[x] = [];
    }

    for (final thought in thoughts) {
      final difference = thought.date.difference(referenceDate);
      double x = 0;
      
      if (_selectedTimeFrame == TimeFrame.monthly) {
        x = difference.inDays / 7;
      } else {
        x = difference.inDays.toDouble();
      }
      
      if (x >= minX && x <= maxX) {
        if (thought.userId == userId) {
          realPoints[x.roundToDouble()]?.add(thought.mentalLoad);
        } else {
          partnerPoints[x.roundToDouble()]?.add(thought.mentalLoad);
        }
      }
    }

    List<FlSpot> realSpots = [];
    List<FlSpot> partnerSpots = [];
    List<FlSpot> predictedSpots = [];

    double getLastKnownValue(List<FlSpot> spots) {
      return spots.isEmpty ? 0 : spots.last.y;
    }

    for (final entry in realPoints.entries.where((e) => e.key <= 0)) {
      if (entry.value.isNotEmpty) {
        final totalLoad = entry.value.reduce((a, b) => a + b);
        realSpots.add(FlSpot(entry.key, totalLoad));
      } else if (realSpots.isNotEmpty) {
        realSpots.add(FlSpot(entry.key, getLastKnownValue(realSpots)));
      }
    }

    for (final entry in partnerPoints.entries.where((e) => e.key <= 0)) {
      if (entry.value.isNotEmpty) {
        final totalLoad = entry.value.reduce((a, b) => a + b);
        partnerSpots.add(FlSpot(entry.key, totalLoad));
      } else if (partnerSpots.isNotEmpty) {
        partnerSpots.add(FlSpot(entry.key, getLastKnownValue(partnerSpots)));
      }
    }

    realSpots.sort((a, b) => a.x.compareTo(b.x));
    partnerSpots.sort((a, b) => a.x.compareTo(b.x));

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
    
    return Distribution(
      userPercentage: totalMinutes == 0 ? 0 : (userDuration.inMinutes / totalMinutes) * 100,
      partnerPercentage: totalMinutes == 0 ? 0 : (partnerDuration.inMinutes / totalMinutes) * 100,
      userDuration: userDuration,
      partnerDuration: partnerDuration,
    );
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

  Widget _buildLegendItem(String text, Color color, {bool isDashed = false}) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            border: isDashed ? Border.all(color: color) : null,
          ),
          child: isDashed
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, 2),
                      painter: DashedLinePainter(color: color),
                    );
                  },
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours${minutes > 0 ? 'h $minutes min' : 'h'}';
    }
    return '$minutes min';
  }

  PredefinedTask? _getRecommendedTask(List<PredefinedTask> tasks) {
    if (tasks.isEmpty) return null;
    
    final sortedTasks = List<PredefinedTask>.from(tasks)
      ..sort((a, b) => b.effort.compareTo(a.effort));
    return sortedTasks.first;
  }

  void _executeTask(BuildContext context, PredefinedTask task) {
    final currentUser = ref.read(currentUserProvider);
    ref.read(taskHistoryProvider.notifier).addTask(
      TaskHistoryItem(
        title: task.title,
        userName: currentUser.name,
        completedAt: DateTime.now(),
        userAvatar: currentUser.avatarUrl,
        duration: task.effort,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "${task.title}" completed'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    
    const dashWidth = 4;
    const dashSpace = 4;
    var start = 0.0;
    
    while (start < size.width) {
      canvas.drawLine(
        Offset(start, 0),
        Offset(start + dashWidth, 0),
        paint,
      );
      start += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
