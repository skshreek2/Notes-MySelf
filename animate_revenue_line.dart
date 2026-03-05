import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hdfc_merchant_app/core/util/common.dart';

class AnimatedRevenueLineChart extends StatefulWidget {
  final List<FlSpot> spots;
  final List<String> dateKeys;
  final double height;
  final String Function(int) getDateLabel;

  const AnimatedRevenueLineChart({
    super.key,
    required this.spots,
    required this.dateKeys,
    required this.height,
    required this.getDateLabel,
  });

  @override
  State<AnimatedRevenueLineChart> createState() =>
      _AnimatedRevenueLineChartState();
}

class _AnimatedRevenueLineChartState extends State<AnimatedRevenueLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _revenueController;
  late Animation<double> revenueAnimation;

  @override
  void initState() {
    super.initState();
    _revenueController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );

    revenueAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revenueController, curve: Curves.easeInOutBack),
    );

    _revenueController.forward();
  }

  @override
  void dispose() {
    _revenueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final maxAmount = widget.spots.isNotEmpty ? widget.spots.map((e) => e.y).reduce(math.max) * 1.1 : 500000.0;
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
          SizedBox(height: 16),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutBack,
              builder: (context, progress, child) {
                final maxVisibleIndex = (widget.dateKeys.length * progress)
                    .floor();
                final visibleSpots = widget.spots
                    .asMap()
                    .entries
                    .where((entry) => entry.key <= maxVisibleIndex)
                    .map((entry) => FlSpot(entry.value.x, entry.value.y))
                    .toList();
                return LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (widget.dateKeys.length - 1).toDouble(),
                    maxY: maxAmount,
                    minY: 0,
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
                        axisNameWidget: Text("Date"),
                        axisNameSize: 15,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= widget.dateKeys.length) {
                              return SizedBox.shrink();
                            }
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
                        axisNameWidget: Text("Amount (₹)"),
                        axisNameSize: 15,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          interval: maxAmount / 5,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Text(
                              '  ${formatVolume(value)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
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
                        spots: visibleSpots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        preventCurveOverShooting: true,
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade400],
                        ),
                        barWidth: 3,
                        dotData: FlDotData(show: true),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
