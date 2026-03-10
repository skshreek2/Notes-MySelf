import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hdfc_merchant_app/core/util/common.dart';
import 'package:hdfc_merchant_app/features/dashboard/model/chart_data.dart';

class AnimatedWeeklyVolumeBarChart extends StatelessWidget {
  // final List<double> amounts;
  // final List<String> dateKeys;
  final ChartData chartData;
  final String Function(int, List<String>) getDateLabel;
  final double height;

  const AnimatedWeeklyVolumeBarChart({
    super.key,
    // required this.amounts,
    // required this.dateKeys,
    required this.chartData,
    required this.getDateLabel,
    required this.height,
  });

  BarChartGroupData _makeGroupData(int x, double y, Color color) {

    const double minimumVisibleHeight = 0.001;
    final double barHeight = y == 0 ? minimumVisibleHeight : y;

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: barHeight,
          color: y == 0 ? Colors.red : color,
          width: y == 0 ? 8 : 20,
          borderRadius: y == 0 ? BorderRadius.circular(2) : BorderRadius.circular(6),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxAmount =
        chartData.volumes.isNotEmpty ? chartData.volumes.reduce(math.max) * 1.1 : 500000.0;

    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 3000),
              curve: Curves.easeOutBack,
              builder: (context, progress, child) {
                final barGroups = List.generate(chartData.volumes.length, (index) {
                  final animatedHeight = chartData.volumes[index] * progress;
                  return _makeGroupData(
                      index, animatedHeight, Colors.blue.shade600);
                });

                return BarChart(
                  BarChartData(
                    maxY: maxAmount,
                    minY: 0,
                    barGroups: barGroups,
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex){
                          double value = rod.toY;
                          if(value <= 0.001){
                            value = 0;
                          }

                          return BarTooltipItem(formatVolume(value), const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),);
                        }
                      )
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text("Date"),
                        axisNameSize: 30,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= chartData.dates.length) {
                              return const SizedBox.shrink();
                            }
                         
                            final dateStr = chartData.dates[index];
                            final dateLabel = formatDateGraph(dateStr);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                dateLabel,
                                textAlign: TextAlign.center,
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
                          getTitlesWidget: (value, meta) => Padding(
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
                          ),
                        ),
                      ),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
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
