import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hdfc_merchant_app/core/util/common.dart';
import 'package:hdfc_merchant_app/features/dashboard/model/chart_data.dart';

class AnimatedRevenueLineChart extends StatefulWidget {
  final ChartData chartData;
  final double height;
  final String Function(int) getDateLabel;

  const AnimatedRevenueLineChart({
    super.key,
    required this.chartData,
    required this.height,
    required this.getDateLabel,
  });

  @override
  State<AnimatedRevenueLineChart> createState() =>
      _AnimatedRevenueLineChartState();
}

class _AnimatedRevenueLineChartState extends State<AnimatedRevenueLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
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

   List<FlSpot> _buildAnimatedSpots(double progress) {
  if (widget.spots.isEmpty) return [];

  final spots = chartData.volumes;
  final total = spots.length;

  final value = progress * (total - 1);
  final index = value.floor();
  final remainder = value - index;

  final animatedSpots = <FlSpot>[];

  // add all completed spots
  for (int i = 0; i <= index && i < total; i++) {
    animatedSpots.add(spots[i]);
  }

  // interpolate next spot
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
    final maxAmount = chartData.volumes.isNotEmpty
        ? widget.spots.map((e) => e.y).reduce(math.max) * 1.1
        : 500000.0;

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
              minY: 0,
              maxY: maxAmount,

              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(context).dividerColor,
                  strokeWidth: 1,
                ),
              ),

              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  axisNameWidget: const Text("Date"),
                  axisNameSize: 30,
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 32,
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
                  axisNameWidget: const Text("Amount (₹)"),
                  axisNameSize: 30,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    interval: maxAmount / 5,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          formatVolume(value),
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

                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade600,
                      Colors.blue.shade400,
                    ],
                  ),

                  barWidth: 3,

                  dotData: FlDotData(show: 
                    animation.value > 0.99,
                  ),

                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
            duration: Duration.zero,
          );
        },
      ),
    );
  }
}
