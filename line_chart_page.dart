import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_charts/gradient_line_chart.dart';

/// Demo screen for [GradientLineChart].
class LineChartPage extends StatelessWidget {
  const LineChartPage({super.key});

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Line chart'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Area under the line uses a gradient from bottom (light) to top (strong).',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GradientLineChart(
                spots: _spots,
                minX: 0,
                maxX: 11,
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
                // Y-axis uses default compact labels (5K, 10K, …) from [GradientLineChart].
              ),
            ),
          ],
        ),
      ),
    );
  }
}
