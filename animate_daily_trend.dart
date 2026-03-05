import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnimatedDailyTrendLineChart extends StatefulWidget {
  final List<FlSpot> spots;
  final List<String> dateKeys;
  final double height;
  final String Function(int) getDateLabel;

  const AnimatedDailyTrendLineChart({
    super.key,
    required this.spots,
    required this.dateKeys,
    required this.height,
    required this.getDateLabel,
  });

  @override
  State<AnimatedDailyTrendLineChart> createState() =>
      _AnimatedDailyTrendLineChartState();
}

class _AnimatedDailyTrendLineChartState
    extends State<AnimatedDailyTrendLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _dailyController;
  late Animation _dailyAnimation;



  @override
  void initState() {
    
    super.initState();

    _dailyController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this);

      _dailyAnimation = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _dailyController, curve: Curves.easeOutBack)
      );

      _dailyController.forward();
  }

  @override
  void dispose() {
    _dailyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final maxCount = widget.spots.isNotEmpty
        ? widget.spots.map((e) => e.y).reduce(math.max).ceil() * 1.1
        : 15.0;
   return Container(
      height: widget.height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          // Text(
          //   'Daily Transactions',
          //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          // ),
          SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (widget.dateKeys.length - 1).toDouble(),
                maxY: maxCount,
                minY: 0,
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text("Date"),
                    axisNameSize: 15,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= widget.dateKeys.length)
                          return SizedBox.shrink();
                        final day = widget.dateKeys[index].substring(8, 10);
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                             widget.getDateLabel(index),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text("Transactions"),
                    axisNameSize: 15,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: (maxCount / 5),
                      getTitlesWidget: (value, meta) {
                        final count = value.toInt();
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Text(
                            '  $count',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: widget.spots,
                    isCurved: true,
                    preventCurveOverShooting:true,
                    color: Colors.purple.shade600,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.purple.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
