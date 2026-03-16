import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hdfc_merchant_app/core/util/common.dart';
import 'package:hdfc_merchant_app/features/dashboard/model/chart_data.dart';
import 'package:hdfc_merchant_app/features/dashboard/presentation/widgets/no_data_widget.dart';

class AnimatedRevenueLineChart extends StatefulWidget {
  final ChartData chartData;
  final double height;

  const AnimatedRevenueLineChart({
    super.key,
    required this.chartData,
    required this.height,
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
      duration: chartDuration,
    );

    animation = CurvedAnimation(parent: controller, curve: Curves.easeOutQuart);

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  List<FlSpot> _buildAnimatedSpots(double progress) {
    final volumes = widget.chartData.volumes;
    if (volumes.isEmpty) return [];

    //final spots = widget.chartData.volumes;
    final total = volumes.length;

    final value = progress * (total - 1);
    final index = value.floor();
    final remainder = value - index;

    final animatedSpots = <FlSpot>[];

    // add all completed spots
    for (int i = 0; i <= index && i < total; i++) {
      animatedSpots.add(FlSpot(i.toDouble(), volumes[i]));
    }

    // interpolate next spot
    if (index + 1 < total) {
      final y1 = volumes[index];
      final y2 = volumes[index + 1];

      // final p1 = spots[index];
      // final p2 = spots[index + 1];

      final x = index + remainder;
      final y = y1 + (y2 - y1) * remainder;

      animatedSpots.add(FlSpot(x, y));
    }

    return animatedSpots;
  }

  @override
  Widget build(BuildContext context) {
    final volumes = widget.chartData.volumes;
    final dateKeys = widget.chartData.dates;

    if (volumes.isEmpty || dateKeys.isEmpty) {
      return NoDataWidget(height: widget.height);
    }

    final maxAmount = volumes.isNotEmpty
        ? volumes.reduce(math.max) * 1.1
        : 500000.0;

    final yInterval = maxAmount / 5;

    return Container(
      height: widget.height,
      padding: const EdgeInsets.fromLTRB(24, 32, 24,24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: math.max(
            MediaQuery.of(context).size.width,
            volumes.length * 80,
          ),

          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final animatedSpots = _buildAnimatedSpots(animation.value);

              return LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (dateKeys.length - 1).toDouble() + 0.3,
                  minY: 0,
                  maxY: maxAmount,

                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: yInterval,
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

                          if (index < 0 || index >= dateKeys.length) {
                            return const SizedBox.shrink();
                          }
                          final dateStr = dateKeys[index];
                          final dateLabel = formatDateGraph(dateStr);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dateLabel,
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
                              formatRupeesCompact(value.toDouble()),
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
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

                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1.2,
                      ),
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1.2,
                      ),
                      left: BorderSide.none,
                      right: BorderSide.none,
                    ),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: animatedSpots,
                      isCurved: true,
                      curveSmoothness: 0.25,
                      preventCurveOverShooting: true,

                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade400],
                      ),

                      barWidth: 3,

                      dotData: FlDotData(show: animation.value > 0.99),

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
        ),
      ),
    );
  }
}
