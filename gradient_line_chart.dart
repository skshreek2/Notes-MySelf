import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Line chart with area fill using a **bottom → top** gradient under the curve.
class GradientLineChart extends StatelessWidget {
  const GradientLineChart({
    super.key,
    required this.spots,
    this.minX,
    this.maxX,
    this.minY,
    this.maxY,
    this.lineColor,
    this.gradientColors,
    this.isCurved = true,
    this.curveSmoothness = 0.08,
    this.barWidth = 3,
    this.showDots = false,
    this.showGrid = true,
    this.tooltipValueColor,
    this.tooltipBackgroundColor,
    this.showYAxisLabels = true,
    this.yAxisLabelFormatter,
    this.bottomTitleBuilder,
    this.leftTitleBuilder,
  });

  final List<FlSpot> spots;
  final double? minX;
  final double? maxX;
  final double? minY;
  final double? maxY;
  final Color? lineColor;
  final List<Color>? gradientColors;
  final bool isCurved;

  /// Lower = sharper corners (fl_chart default is 0.35).
  final double curveSmoothness;
  final double barWidth;
  final bool showDots;
  final bool showGrid;
  final Color? tooltipValueColor;
  final Color? tooltipBackgroundColor;
  final bool showYAxisLabels;
  final String Function(double value)? yAxisLabelFormatter;
  final Widget Function(double value, TitleMeta meta)? bottomTitleBuilder;
  final Widget Function(double value, TitleMeta meta)? leftTitleBuilder;

  /// Formats axis values: 5000 → 5K, 10000 → 10K, 1500000 → 1.5M, etc.
  static String formatCompactAxis(double n) {
    final abs = n.abs();
    if (abs >= 1e9) {
      return '${_trimCompact(n / 1e9)}B';
    }
    if (abs >= 1e6) {
      return '${_trimCompact(n / 1e6)}M';
    }
    if (abs >= 1e3) {
      return '${_trimCompact(n / 1e3)}K';
    }
    return n.round().toString();
  }

  static String _trimCompact(double x) {
    var s = x.toStringAsFixed(1);
    if (s.endsWith('.0')) {
      s = s.substring(0, s.length - 2);
    }
    return s;
  }

  /// Picks a readable tick step (~5 labels) for the Y axis.
  static double _yAxisInterval(double maxY) {
    if (maxY <= 0) return 1;
    const targetTicks = 5;
    final rough = maxY / targetTicks;
    final exp = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
    final normalized = rough / exp;
    final nice = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;
    return nice * exp;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final line = lineColor ?? colorScheme.primary;
    final fillColors =
        gradientColors ??
        [
          line.withValues(alpha: 0.05),
          line.withValues(alpha: 0.25),
          line.withValues(alpha: 0.55),
        ];

    final dataMinY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final dataMaxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final chartMinY = minY ?? (dataMinY >= 0 ? 0.0 : dataMinY * 1.1);
    final chartMaxY =
        maxY ?? (dataMaxY * 1.15).clamp(dataMaxY + 1, double.infinity);
    final yInterval = _yAxisInterval(chartMaxY);
    final formatY = yAxisLabelFormatter ?? formatCompactAxis;

    return LineChart(
      LineChartData(
        minX: minX ?? spots.first.x,
        maxX: maxX ?? spots.last.x,
        minY: chartMinY,
        maxY: chartMaxY,
        gridData: FlGridData(
          show: showGrid,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: bottomTitleBuilder != null,
              reservedSize: 28,
              getTitlesWidget:
                  bottomTitleBuilder ??
                  (double value, TitleMeta meta) => const SizedBox.shrink(),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: showYAxisLabels,
              reservedSize: 44,
              interval: yInterval,
              minIncluded: true,
              maxIncluded: true,
              getTitlesWidget:
                  leftTitleBuilder ??
                  (double value, TitleMeta meta) {
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        formatY(value),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                tooltipBackgroundColor ?? colorScheme.inverseSurface,
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItems: (touchedSpots) {
              final valueColor =
                  tooltipValueColor ?? colorScheme.onInverseSurface;
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  spot.y.toStringAsFixed(1),
                  TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: isCurved,
            curveSmoothness: curveSmoothness,
            barWidth: barWidth,
            color: line,
            dashArray: [4, 4],
            isStrokeCapRound: true,
            dotData: FlDotData(show: showDots),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: fillColors,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }
}
