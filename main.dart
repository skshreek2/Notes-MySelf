import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Charts',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HorizontalBarChartPage(),
    );
  }
}

class HorizontalBarChartPage extends StatefulWidget {
  const HorizontalBarChartPage({super.key});

  @override
  State<HorizontalBarChartPage> createState() => _HorizontalBarChartPageState();
}

class _HorizontalBarChartPageState extends State<HorizontalBarChartPage> {
  static const _labels = ['Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon'];
  static const _values = <double>[42, 28, 56, 35, 48];
  static const _maxY = 60.0;

  /// When false, bars use `toY: 0` so the next build animates outward (reads as horizontal growth with rotation).
  bool _showValues = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _showValues = true);
      }
    });
  }

  void _replayAnimation() {
    setState(() => _showValues = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _showValues = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horizontal bar chart'),
        actions: [
          IconButton(
            tooltip: 'Replay grow animation',
            onPressed: _replayAnimation,
            icon: const Icon(Icons.replay),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bars extend along the horizontal axis; tap replay to animate again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: BarChart(
                BarChartData(
                  rotationQuarterTurns: 1,
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _maxY,
                  minY: 0,
                  barTouchData: const BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(),
                    // With rotationQuarterTurns: 1, [rightTitles] maps to the
                    // bottom of the screen — use it for the 0, 10, 20… value axis.
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 10,
                        minIncluded: true,
                        maxIncluded: true,
                        getTitlesWidget: (value, meta) {
                          final v = value.round();
                          if (v < 0 || v > _maxY.toInt()) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 4,
                            child: Text(
                              '$v',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 72,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= _labels.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 4,
                            child: Text(
                              _labels[i],
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
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
                    show: true,
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                      strokeWidth: 1,
                    ),
                  ),
                  barGroups: List.generate(_labels.length, (i) {
                    final y = _showValues ? _values[i] : 0.0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: y,
                          fromY: 0,
                          width: 14,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.85),
                              colorScheme.tertiary,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
