import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/thoughts_provider.dart';
import '../providers/current_user_provider.dart';
import '../models/thought.dart';
import '../utils/mock_data.dart';

enum TimeFrame { daily, weekly, monthly, yearly }

class _DataPoints {
  final List<FlSpot> real;
  final List<FlSpot> predicted;
  final List<FlSpot> partner;
  final List<FlSpot> partnerPredicted;
  
  _DataPoints(this.real, this.predicted, this.partner, this.partnerPredicted);
}

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  TimeFrame _selectedTimeFrame = TimeFrame.daily;

  @override
  Widget build(BuildContext context) {
    final thoughts = ref.watch(thoughtsProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Mental Load Stats'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
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
                        setState(() => _selectedTimeFrame = timeFrame);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: thoughts.isEmpty
                  ? Center(child: Text('No thoughts yet'))
                  : buildThoughtsChart(thoughts),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildThoughtsChart(List<Thought> thoughts) {
    final currentUser = ref.watch(currentUserProvider);
    final now = DateTime.now();
    
    // Add mock data if thoughts list is empty
    if (thoughts.isEmpty) {
      thoughts = MockData.generateMockThoughts();
    }

    // Configure time frame settings
    final (period, format, minX, maxX, xInterval) = switch (_selectedTimeFrame) {
      TimeFrame.daily => (
        Duration(hours: 1),
        'HH:mm',
        -23.0,
        1.0,  // +1 for prediction
        3.0,
      ),
      TimeFrame.weekly => (
        Duration(days: 1),
        'E',
        -6.0,
        1.0,
        1.0,
      ),
      TimeFrame.monthly => (
        Duration(days: 1),
        'd MMM',
        -29.0,
        2.0,
        5.0,
      ),
      TimeFrame.yearly => (
        Duration(days: 30),
        'MMM',
        -11.0,
        1.0,
        1.0,
      ),
    };

    // Group and calculate data points
    final spots = _calculateDataPoints(
      thoughts,
      currentUser.id,
      period,
      minX,
      maxX,
    );

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
                getTitlesWidget: (value, meta) {
                  final date = now.add(Duration(
                    hours: _selectedTimeFrame == TimeFrame.daily ? value.toInt() : 0,
                    days: _selectedTimeFrame != TimeFrame.daily ? value.toInt() : 0,
                  ));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(DateFormat(format).format(date)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
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
          maxY: 10,
          lineBarsData: [
            // Current user line
            LineChartBarData(
              spots: spots.real,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              dotData: FlDotData(show: true),
            ),
            // Current user prediction
            LineChartBarData(
              spots: spots.predicted,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              dotData: FlDotData(show: false),
              dashArray: [5, 5],
            ),
            // Partner line
            LineChartBarData(
              spots: spots.partner,
              isCurved: true,
              color: Colors.blue,
              dotData: FlDotData(show: true),
            ),
            // Partner prediction
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
    final Map<double, List<double>> realPoints = {};
    final Map<double, List<double>> partnerPoints = {};

    // Initialize maps with empty lists for all x values
    for (double x = minX; x <= maxX; x += 1) {
      realPoints[x] = [];
      partnerPoints[x] = [];
    }

    // Group thoughts by time period
    for (final thought in thoughts) {
      final difference = thought.date.difference(now);
      double x = 0;
      
      if (_selectedTimeFrame == TimeFrame.daily) {
        x = difference.inHours.toDouble();
      } else if (_selectedTimeFrame == TimeFrame.yearly) {
        x = difference.inDays / 30;
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

    // Calculate averages and create spots
    List<FlSpot> realSpots = [];
    List<FlSpot> partnerSpots = [];
    List<FlSpot> predictedSpots = [];

    for (final entry in realPoints.entries.where((e) => e.key <= 0)) {
      final avgLoad = entry.value.isEmpty ? 0.0 : 
          entry.value.reduce((a, b) => a + b) / entry.value.length;
      realSpots.add(FlSpot(entry.key, avgLoad));
    }

    for (final entry in partnerPoints.entries.where((e) => e.key <= 0)) {
      final avgLoad = entry.value.isEmpty ? 0.0 : 
          entry.value.reduce((a, b) => a + b) / entry.value.length;
      partnerSpots.add(FlSpot(entry.key, avgLoad));
    }

    // Calculate prediction
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

    // Calculate trend for predictions
    double trend = 0.0;
    if (realSpots.length > 1) {
      trend = (realSpots.last.y - realSpots[realSpots.length - 2].y);
    }

    double partnerTrend = 0.0;
    if (partnerSpots.length > 1) {
      partnerTrend = (partnerSpots.last.y - partnerSpots[partnerSpots.length - 2].y);
    }

    return _DataPoints(
      [...realSpots..sort((a, b) => a.x.compareTo(b.x))],
      predictedSpots,
      [...partnerSpots..sort((a, b) => a.x.compareTo(b.x))],
      partnerSpots.isEmpty ? [] : [
        FlSpot(0, partnerSpots.last.y),
        FlSpot(maxX, partnerSpots.last.y + (partnerTrend * maxX)),
      ],
    );
  }
} 