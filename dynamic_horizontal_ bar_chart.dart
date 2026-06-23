import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// One row in [DynamicHorizontalBarChart].
class HorizontalBarEntry {
  const HorizontalBarEntry({
    required this.label,
    required this.value,
    this.color,
    this.valueLabel,
    required this.sqrtval,
  });

  final String label;
  final double value;
  final double sqrtval;

  /// Optional override for the in-bar text (e.g. `₹4.2 Cr`).
  final String? valueLabel;
  final Color? color;
}

class DynamicHorizontalBarChart extends StatefulWidget {
  const DynamicHorizontalBarChart({
    super.key,
    required this.entries,
    this.valueFormatter,
    this.maxY,
    this.animate = true,
    this.barWidth,
    this.endGap = 5,
    this.minLabelFontSize = 5,
    this.maxLabelFontSize = 11,
  });

  final List<HorizontalBarEntry> entries;

  /// Builds the string shown inside each bar. Default: plain number.
  final String Function(double value)? valueFormatter;

  /// Y-axis max; when null, derived from the largest [HorizontalBarEntry.value].
  final double? maxY;

  final bool animate;
  final double? barWidth;
  final double endGap;
  final double minLabelFontSize;
  final double maxLabelFontSize;

  @override
  State<DynamicHorizontalBarChart> createState() =>
      _DynamicHorizontalBarChartState();
}

class _DynamicHorizontalBarChartState extends State<DynamicHorizontalBarChart> {
  // bool _showBars = false;

  double get _maxY {
    if (widget.maxY != null) return widget.maxY!;
    if (widget.entries.isEmpty) return 1;
    final max = widget.entries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    return max <= 0 ? 1 : max * 1.08;
  }

  String _labelFor(HorizontalBarEntry entry) =>
      entry.valueLabel ??
      (widget.valueFormatter?.call(entry.value) ?? _formatNumber(entry.value));

  static String _formatNumber(double n) {
    final v = n.round();
    if (v == 0) return '0';
    final neg = v < 0;
    var s = v.abs().toString();
    final groups = <String>[];
    while (s.length > 3) {
      groups.add(s.substring(s.length - 3));
      s = s.substring(0, s.length - 3);
    }
    if (s.isNotEmpty) groups.add(s);
    return (neg ? '-' : '') + groups.reversed.join(',');
  }

  static double _axisInterval(double maxY) {
    if (maxY <= 10) return 1;
    if (maxY <= 100) return 10;
    if (maxY <= 1000) return 100;
    final raw = maxY / 6;
    final mag = raw <= 0 ? 1.0 : _pow10(raw).toDouble();
    return (raw / mag).ceil() * mag;
  }

  static int _pow10(double x) {
    var p = 1;
    while (p < x) {
      p *= 10;
    }
    return p;
  }

  bool _labelFits(
    BuildContext context, {
    required String text,
    required double fontSize,
    required double chartWidth,
    required double chartHeight,
    required double y,
    required int barCount,
    required double endGap,
  }) {
    if (y <= 0 || chartWidth <= 0 || chartHeight <= 0) return false;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();

    final barPixelWidth = chartWidth * (y / _maxY);
    final availableWidth = (barPixelWidth - endGap - 12).clamp(
      0.0,
      double.infinity,
    );

    return tp.width <= availableWidth;
  }

  double _measureTextHeight(
    BuildContext context, {
    required String text,
    required TextStyle style,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();

    return tp.height;
  }

  final labelStyle = const TextStyle(
    color: Colors.black,
    fontSize: 12,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.normal,
    height: 1.2,
  );

  String _fitTextEllipsis(
    BuildContext context, {
    required String text,
    required double fontSize,
    required double chartWidth,
    required double y,
    required double endGap,
  }) {
    final barPixelWidth = chartWidth * (y / _maxY);
    final availableWidth = (barPixelWidth - endGap - 12).clamp(
      0.0,
      double.infinity,
    );

    if (availableWidth <= 0) return '';

    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
      height: 1.2,
    );

    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
      // ellipsis: '…',
    );

    painter.text = TextSpan(text: text, style: style);
    painter.layout(maxWidth: availableWidth);

    final end = painter
        .getPositionForOffset(Offset(availableWidth, painter.height / 2))
        .offset;

    if (!painter.didExceedMaxLines) return text;
    // if (end <= 1) return '…';

    return '${text.substring(0, end - 1)}';
  }

  double _dynamicRodWidth(
    BuildContext context, {
    required String text,
    required double baseWidth,
    required TextStyle style,
    int minCharacters = 8,
    double verticalPadding = 20,
  }) {
    final effectiveText = text.length >= minCharacters
        ? text
        : text.padRight(minCharacters, '0');

    final textHeight = _measureTextHeight(
      context,
      text: effectiveText,
      style: style,
    );

    final requiredWidth = textHeight + verticalPadding;
    return requiredWidth > baseWidth ? requiredWidth : baseWidth;
  }

  double _tipInsetDy(
    BuildContext context, {
    required String text,
    required double fontSize,
    required double endGap,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final widthPull = (tp.width * 0.26).clamp(10.0, 88.0);
    const extraTopPadding = 6.0;
    return 10 + fontSize * 2.8 + widthPull + endGap + extraTopPadding;
  }

  double _minYToFitText(
    BuildContext context, {
    required String text,
    required TextStyle style,
    required double chartWidth,
    required double endGap,
    double extraPadding = 12,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();

    final requiredPixelWidth = tp.width + endGap + extraPadding;

    // Convert required pixels into chart value units.
    final minY = (requiredPixelWidth / chartWidth) * _maxY;
    return minY;
  }

  String _textForMinFit(String text, {int minChars = 5}) {
    if (text.length >= minChars) return text;
    return text.padRight(minChars, '0');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final count = widget.entries.length;
    final interval = _axisInterval(_maxY);

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartW = constraints.maxWidth;
        final chartH = constraints.maxHeight;
        final rodWidth =
            widget.barWidth ?? (chartH / count * 0.60).clamp(24.0, 56.0);

        return BarChart(
          BarChartData(
            rotationQuarterTurns: 1,
            alignment: BarChartAlignment.center,
            groupsSpace: 20,
            maxY: _maxY,
            minY: 0,
            barTouchData: const BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                  reservedSize: 44,
                  interval: interval,
                  minIncluded: true,
                  maxIncluded: true,
                  getTitlesWidget: (value, meta) {
                    if (value < 0 || value > _maxY) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 4,
                      child: Text(
                        widget.valueFormatter?.call(value) ??
                            _formatNumber(value),
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 100,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= count) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 4,
                      child: Container(
                        width: 90,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.entries[i].label,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: false,
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
            ),
            gridData: FlGridData(
              show: false,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                strokeWidth: 1,
              ),
            ),
            barGroups: List.generate(count, (i) {
              final entry = widget.entries[i];
              final labelText = _labelFor(entry);

              final y = entry.value;
              final minFitText = _textForMinFit(labelText, minChars: 6);

              final minYNeeded = _minYToFitText(
                context,
                text: minFitText,
                style: labelStyle,
                chartWidth: chartW,
                endGap: widget.endGap,
              );

              final baseRodWidth =
                  widget.barWidth ?? (chartH / count * 0.68).clamp(30.0, 64.0);

              final rodWidth = _dynamicRodWidth(
                context,
                text: labelText,
                baseWidth: baseRodWidth,
                style: labelStyle,
                minCharacters: 8,
              );

              const fontSize = 12.0;
              final fits = _labelFits(
                context,
                text: labelText,
                fontSize: fontSize,
                chartWidth: chartW,
                chartHeight: chartH,
                y: y,
                barCount: count,
                endGap: widget.endGap,
              );

              final minVisiblePercent = _maxY * 0.03;
              // final displayY = y < minVisiblePercent ? minVisiblePercent : y;
              final displayY = y == 0 ? minVisiblePercent : y;
              final finalLabel = fits
                  ? labelText
                  : _fitTextEllipsis(
                      context,
                      text: labelText,
                      fontSize: fontSize,
                      chartWidth: chartW,
                      y: displayY,
                      endGap: widget.endGap,
                    );

              final barColor = entry.color ?? colorScheme.primary;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: displayY,
                    fromY: 0,

                    width: rodWidth,
                    color: Color(0xFFD8D6EE),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      // bottomRight: Radius.circular(6),
                      topLeft: Radius.circular(8),
                      // bottomLeft: Radius.circular(6),
                    ),
                    gradient: LinearGradient(
                      colors: [Color(0xFFB2C7FC), Color(0xFFB2C7FC)],
                      stops: [0.0, 1.0],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    label: BarChartRodLabel(
                      show: y > 0 && finalLabel.isNotEmpty,
                      text: finalLabel,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: fontSize,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                        height: 1.5,
                      ),
                      offset: fits
                          ? const Offset(0, -40)
                          : const Offset(0, -32),
                    ),
                    borderSide: BorderSide(
                      color: Color.fromRGBO(137, 26, 205, 0.10),
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                ],
              );
            }),
          ),
          duration: widget.animate
              ? const Duration(milliseconds: 900)
              : Duration.zero,
          curve: Curves.easeOutCubic,
        );
      },
    );
  }
}
