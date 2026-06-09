import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hdfc_merchant_app/features/dashboard/ui/widgets/gradient_line_chart.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/data/payment_response_model.dart';

class LineChartPage extends StatelessWidget {
  List<MonthlyTrendModel> monthlyTrend;
  LineChartPage({super.key, required this.monthlyTrend});

  static final _spots = <FlSpot>[
    const FlSpot(0, 10000),
    const FlSpot(1, 18000),
    const FlSpot(2, 14000),
    const FlSpot(3, 26000),
    const FlSpot(4, 22000),
    const FlSpot(5, 8000),
    const FlSpot(6, 12000),
    const FlSpot(7, 42000),
    const FlSpot(8, 38000),
    const FlSpot(9, 20000),
    const FlSpot(10, 46000),
    const FlSpot(11, 58000),
  ];


  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // print("monthlyTrend---> ${monthlyTrend.}");

    for (final item in monthlyTrend) {
      print('Month: ${item.month}, Amount: ${item.amount}');
    }
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: GradientLineChart(
              spots: _spots,
              minX: 0,
              maxX: 11,
              maxY: 60000,
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
                if (i < 0 || i >= _months.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _months[i],
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
