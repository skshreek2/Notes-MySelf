import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hdfc_merchant_app/core/util/common.dart';

class WeeklyVolumeBarChart extends StatelessWidget {
  final List<double> amounts;
  final List<String> dateKeys;
  final String Function(int) getDateLabel;
  final double height;

  const WeeklyVolumeBarChart({
    super.key,
    required this.amounts,
    required this.dateKeys,
    required this.getDateLabel,
    required this.height,
  });

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y.clamp(0.0, double.infinity),
          color: color,
          width: 20,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxAmount =
        amounts.isNotEmpty ? amounts.reduce(math.max) * 1.1 : 500000.0;

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
                final barGroups = List.generate(amounts.length, (index) {
                  final animatedHeight = amounts[index] * progress;
                  return _makeGroupData(
                      index, animatedHeight, Colors.blue.shade600);
                });

                return BarChart(
                  BarChartData(
                    maxY: maxAmount,
                    minY: 0,
                    barGroups: barGroups,
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text("Date"),
                        axisNameSize: 15,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= dateKeys.length) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                getDateLabel(index),
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
                        axisNameSize: 15,
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
