import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hdfc_merchant_app/core/util/common.dart';
import 'package:hdfc_merchant_app/features/dashboard/model/chart_data.dart';
import 'package:hdfc_merchant_app/features/dashboard/presentation/graphs/base_chart_container.dart';
import 'package:hdfc_merchant_app/features/dashboard/presentation/graphs/chart_animation_wrapper.dart';
import 'package:hdfc_merchant_app/features/dashboard/presentation/widgets/no_data_widget.dart';

class AnimatedWeeklyVolumeBarChart extends StatelessWidget {
  final ChartData chartData;
  final double height;

  const AnimatedWeeklyVolumeBarChart({
    super.key,
    required this.chartData,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final volumes = chartData.volumes;
    final dateKeys = chartData.dates;
    // print("volumes $volumes");
    // print("Dates $dateKeys");
    // volumes [0, 0, 0, 0, 0, 700000, 1500000, 1570000, 3100000, 4100000, 0]
    // Dates [2026-01-10, 2026-01-11, 2026-01-12, 2026-01-13, 2026-01-14, 2026-01-15, 2026-01-16, 2026-01-17, 2026-01-18, 2026-01-19, 2026-01-20]

    if (volumes.isEmpty || dateKeys.isEmpty) {
      return NoDataWidget(height: height);
    }

    final maxAmount = volumes.isNotEmpty
        ? volumes.reduce(math.max) * 1.1
        : 500000.0;
  // print("maxAmount $maxAmount");
    
    return BaseChartContainer(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double chartWidth = math.max(
                  constraints.maxWidth,
                  volumes.length * 70,
                );
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    child: ChartAnimationWrapper(
                      builder: (progress) {
                        
                        final barGroups = List.generate(volumes.length, (index) {

                          return BarChartGroupData(x: index,
                            barRods: [
                              BarChartRodData(
                              toY: volumes[index] * progress,
                              width: 20,
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.blue)
                            ]
                          );
                        });
                        final yInterval = maxAmount / 5;

                        // print("barGroups $barGroups");
                        return BarChart(
                          BarChartData(
                            maxY: maxAmount,
                            minY: 0,

                            barGroups: barGroups,
                            alignment: BarChartAlignment.spaceAround,
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: yInterval,
                              verticalInterval: 1,
                              drawHorizontalLine: true,
                              drawVerticalLine: true,
                              getDrawingHorizontalLine: (value) {
                                const tolerance = 0.001;

                                if ((value - 0).abs() < tolerance ||
                                    (value - maxAmount).abs() < tolerance) {
                                  return FlLine(
                                    color: Colors.grey.withOpacity(0.33),
                                    strokeWidth: 1.2,
                                  );
                                }
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.3),
                                  strokeWidth: 1,
                                );
                              },
                              getDrawingVerticalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.15),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.withOpacity(0.4),
                                  width: 1.2,
                                ),
                                top: BorderSide(
                                  color: Colors.grey.withOpacity(0.4),
                                  width: 1.2,
                                ),
                                left: BorderSide.none,
                                right: BorderSide.none,
                              ),
                            ),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                      double value = rod.toY;
                                      if (value <= 0.001) {
                                        value = 0;
                                      }

                                      return BarTooltipItem(
                                        formatVolume(value),
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                              ),
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
                                    if (index < 0 || index >= dateKeys.length) {
                                      return const SizedBox.shrink();
                                    }

                                    final dateStr = dateKeys[index];
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
                          ),
                        );
                      },
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
