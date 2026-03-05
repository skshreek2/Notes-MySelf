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

  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutQuart,
    );

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Smooth interpolation animation
  List<FlSpot> _buildAnimatedSpots(double progress) {
    if (widget.spots.isEmpty) return [];

    final spots = widget.spots;
    final total = spots.length;

    final value = progress * (total - 1);
    final index = value.floor();
    final remainder = value - index;

    final animatedSpots = <FlSpot>[];

    for (int i = 0; i <= index && i < total; i++) {
      animatedSpots.add(spots[i]);
    }

    if (index + 1 < total) {
      final p1 = spots[index];
      final p2 = spots[index + 1];

      final x = p1.x + (p2.x - p1.x) * remainder;
      final y = p1.y + (p2.y - p1.y) * remainder;

      animatedSpots.add(FlSpot(x, y));
    }

    return animatedSpots;
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
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {

          final animatedSpots = _buildAnimatedSpots(animation.value);

          return LineChart(
            LineChartData(
              minX: 0,
              maxX: (widget.dateKeys.length - 1).toDouble(),
              maxY: maxCount,
              minY: 0,

              gridData: FlGridData(show: true),

              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  axisNameWidget: const Text("Date"),
                  axisNameSize: 15,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (value, meta) {

                      final index = value.toInt();

                      if (index < 0 || index >= widget.dateKeys.length) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          widget.getDateLabel(index),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                leftTitles: AxisTitles(
                  axisNameWidget: const Text("Transactions"),
                  axisNameSize: 15,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: maxCount / 5,
                    getTitlesWidget: (value, meta) {

                      final count = value.toInt();

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          "$count",
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),

              borderData: FlBorderData(show: false),

              lineBarsData: [
                LineChartBarData(
                  spots: animatedSpots,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  preventCurveOverShooting: true,

                  color: Colors.purple.shade600,
                  barWidth: 3,

                  dotData: FlDotData(
                    show: animation.value > 0.99,
                  ),

                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.purple.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
