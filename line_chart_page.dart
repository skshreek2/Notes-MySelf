import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hdfc_merchant_app/features/dashboard/ui/widgets/gradient_line_chart.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/data/payment_response_model.dart';

class LineChartPage extends StatelessWidget {
  List<MonthlyTrendModel> monthlyTrend;
  LineChartPage({super.key, required this.monthlyTrend});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (monthlyTrend.isEmpty) {
      return Center(
        child: Text(
          'No data found',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final spots = monthlyTrend.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return FlSpot(index.toDouble(), item.amount.toDouble());
    }).toList();

    final maxY = monthlyTrend.isEmpty
        ? 100
        : monthlyTrend.map((e) => e.amount).reduce((a, b) => a > b ? a : b) *
              1.2;
    print("maxY $maxY");
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: GradientLineChart(
              spots: spots,
              minX: 0,
              maxX: (spots.length - 1).toDouble(),
              minY: 0,
              maxY: maxY.toDouble(),
              lineColor: colorScheme.primary,
              gradientColors: [
                colorScheme.primary.withValues(alpha: 0.0),
                colorScheme.primary.withValues(alpha: 0.2),
                colorScheme.tertiary.withValues(alpha: 0.5),
              ],
              tooltipBackgroundColor: colorScheme.primary,
              tooltipValueColor: Colors.white,
              bottomTitleBuilder: (value, meta) {
                if (value % 1 != 0) return const SizedBox.shrink();
                final i = value.toInt();
                if (i < 0 || i >= monthlyTrend.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    monthlyTrend[i].month,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
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
