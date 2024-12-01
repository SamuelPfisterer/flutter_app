import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/thoughts_provider.dart';
import '../providers/current_user_provider.dart';
import '../models/thought.dart';
import '../utils/mock_data.dart';
import '../theme/app_theme.dart';

enum TimeFrame { weekly, monthly }

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
  TimeFrame _selectedTimeFrame = TimeFrame.weekly;
  int _weekOffset = 0;  // Add week offset state

  @override
  Widget build(BuildContext context) {
    final thoughts = ref.watch(thoughtsProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Mental Load History'),
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
                        setState(() {
                          _selectedTimeFrame = timeFrame;
                          _weekOffset = 0;  // Reset offset when changing view
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
                        : null,  // Disable when at current week
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: thoughts.isEmpty
                  ? Center(child: Text('No thoughts yet'))
                  : Column(
                      children: [
                        Expanded(child: buildThoughtsChart(thoughts)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            children: [
                              _buildLegendItem(
                                'Your mental load',
                                AppColors.userColor.withOpacity(0.8),
                                isDashed: false,
                              ),
                              const SizedBox(height: 8),
                              _buildLegendItem(
                                'Partner\'s mental load',
                                const Color(0xFF7EA668), // Darker green derived from partnerColor
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
      ),
    );
  }

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
    for (var spot in [...spots.real, ...spots.partner]) {
      if (spot.y > maxY) maxY = spot.y;
    }
    // Add 20% padding to the max Y value and round up to nearest 5
    maxY = (maxY * 1.2).roundToDouble();
    if (maxY % 5 != 0) {
      maxY = (maxY / 5).ceil() * 5;
    }
    maxY = maxY == 0 ? 10 : maxY;  // Default to 10 if no data

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
                    days: value.toInt() * 7,  // Multiply by 7 for weekly intervals
                  ));
                  
                  // Calculate week difference for monthly view
                  final weekDiff = value.toInt();
                  
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
                interval: maxY <= 20 ? 2 : 5,  // Adjust interval based on range
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
            // Current user line
            LineChartBarData(
              spots: spots.real,
              isCurved: true,
              color: AppColors.userColor.withOpacity(0.8),
              dotData: FlDotData(show: true),
            ),
            // Current user prediction
            LineChartBarData(
              spots: spots.predicted,
              isCurved: true,
              color: AppColors.userColor.withOpacity(0.8),
              dotData: FlDotData(show: false),
              dashArray: [5, 5],
            ),
            // Partner line
            LineChartBarData(
              spots: spots.partner,
              isCurved: true,
              color: const Color(0xFF7EA668), // Darker green derived from partnerColor
              dotData: FlDotData(show: true),
            ),
            // Partner prediction
            LineChartBarData(
              spots: spots.partnerPredicted,
              isCurved: true,
              color: const Color(0xFF7EA668), // Darker green derived from partnerColor
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
        // Sum up all mental loads for this time point
        final totalLoad = entry.value.reduce((a, b) => a + b);
        realSpots.add(FlSpot(entry.key, totalLoad));
      } else if (realSpots.isNotEmpty) {
        // If no data for this point, use the last known value
        realSpots.add(FlSpot(entry.key, getLastKnownValue(realSpots)));
      }
    }

    // Process partner points - use sum instead of average
    for (final entry in partnerPoints.entries.where((e) => e.key <= 0)) {
      if (entry.value.isNotEmpty) {
        // Sum up all mental loads for this time point
        final totalLoad = entry.value.reduce((a, b) => a + b);
        partnerSpots.add(FlSpot(entry.key, totalLoad));
      } else if (partnerSpots.isNotEmpty) {
        // If no data for this point, use the last known value
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