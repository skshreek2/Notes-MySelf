import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hdfc_merchant_app/features/analytics/data/analytics_model.dart';

class TransactionVolumeChart extends StatefulWidget {
  final List<TransactionVolumeTrend> volumes;

  const TransactionVolumeChart({super.key, required this.volumes});

  @override
  State<TransactionVolumeChart> createState() => _TransactionVolumeChartState();
}

class _TransactionVolumeChartState extends State<TransactionVolumeChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    const allMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final monthValueMap = <String, double>{};

    for (final item in widget.volumes) {
      final month = item.month.substring(0, 3);
      monthValueMap[month] = item.amount.toDouble();
    }

    final values = allMonths
        .map((month) => monthValueMap[month] ?? 0.0)
        .toList();

    final maxValue = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final maxY = maxValue == 0 ? 100.0 : maxValue * 1.2;

    return Expanded(
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          minY: 0,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = allMonths[group.x.toInt()];
                final amount = values[group.x.toInt()];
                return BarTooltipItem(
                  '$month\n₹${amount.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            touchCallback: (event, response) {
              setState(() {
                if (!event.isInterestedForInteractions || response?.spot == null) {
                  touchedIndex = null;
                  return;
                }
                touchedIndex = response!.spot!.touchedBarGroupIndex;
              });
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= allMonths.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      allMonths[index],
                      style: const TextStyle(
                        color: Color(0XFF94A3B8),
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(allMonths.length, (index) {
            final isTouched = touchedIndex == index;
            final isMissing = values[index] == 0;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: values[index],
                  width: 18,
                  borderRadius: BorderRadius.circular(8),
                  color: isTouched
                      ? null
                      : isMissing
                          ? const Color(0xFFE2E8F0)
                          : const Color(0XFFB2C7FC),
                  gradient: isTouched
                      ? const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF002783), Color(0xFF1957B1)],
                        )
                      : null,
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: const Color(0xFFF1F5F9),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
