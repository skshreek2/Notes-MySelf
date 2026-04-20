import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hdfc_merchant_app/core/util/common.dart';
import 'package:hdfc_merchant_app/features/dashboard/ui/widgets/transaction_chart_legend.dart';
import 'package:hdfc_merchant_app/features/dashboard/ui/widgets/transaction_summary_header.dart';
import 'package:intl/intl.dart';
import 'package:hdfc_merchant_app/features/payments/data/orders_entity.dart';

import '../../../../core/util/gif_progressbar.dart';

class DetailedTransactionChart extends StatefulWidget {
  final List<TransactionEntity> orders;
  final Map<String, double> dailyData; // ✅ Updated to accept String keys
  final DateTime? startDate;
  final DateTime? endDate;

  const DetailedTransactionChart({
    super.key,
    required this.orders,
    required this.dailyData,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<DetailedTransactionChart> createState() =>
      _DetailedTransactionChartState();
}

class _DetailedTransactionChartState extends State<DetailedTransactionChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Map<String, List<TransactionEntity>> dailyTransactions = {};
  List<String> dateKeys = [];
  List<FlSpot> successSpots = [];
  List<FlSpot> failedSpots = [];
  bool isDataReady = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _processTransactions();
  }

  @override
  void didUpdateWidget(DetailedTransactionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orders != widget.orders ||
        oldWidget.dailyData != widget.dailyData) {
      _processTransactions();
    }
  }

  void _processTransactions() {
    final Map<String, List<TransactionEntity>> parsedData = {};

    final dateFormat = DateFormat('MMM dd');

    if (widget.startDate != null && widget.endDate != null) {
      DateTime current = widget.startDate!.copyWith();
      final end = widget.endDate!.copyWith();

      while (!current.isAfter(end)) {
        final dateStr = dateFormat.format(current);
        parsedData[dateStr] = [];
        current = current.add(const Duration(days: 1));
      }
    }

    // ✅ Use date filtering from parent instead of fixed 15 days
    for (final transaction in widget.orders) {
      final dateStr = DateFormat('MMM dd').format(transaction.date);
      parsedData.putIfAbsent(dateStr, () => []).add(transaction);
    }

    dateKeys = parsedData.keys.toList()
      ..sort((a, b) {
        // Sort by actual date order
        final dateA = DateFormat('MMM dd').parse(a);
        final dateB = DateFormat('MMM dd').parse(b);
        return dateA.compareTo(dateB);
      });

    _buildSpots(parsedData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          dailyTransactions = parsedData;
          isDataReady = dateKeys.isNotEmpty;
        });
      }
    });
  }

  void _buildSpots(Map<String, List<TransactionEntity>> parsedData) {
    successSpots = dateKeys.asMap().entries.map((entry) {
      final transactions = parsedData[entry.value] ?? [];
      final successCount = transactions
          .where((tx) => tx.status == TransactionStatus.success)
          .length;
      return FlSpot(entry.key.toDouble(), successCount.toDouble());
    }).toList();

    failedSpots = dateKeys.asMap().entries.map((entry) {
      final transactions = parsedData[entry.value] ?? [];
      final failedCount = transactions
          .where((tx) => tx.status != TransactionStatus.success)
          .length;
      return FlSpot(entry.key.toDouble(), failedCount.toDouble());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orders.isEmpty ||
        !isDataReady ||
        dateKeys.isEmpty ||
        successSpots.isEmpty ||
        failedSpots.isEmpty) {
      return SizedBox(
        height: 240,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            // child: CircularProgressIndicator(),
            child: GifProgressBar(),
          ),
        ),
      );
    }

    final totalDays = dateKeys.length;
    final totalSuccess = dateKeys.fold<int>(0, (sum, dateKey) {
      final transactions = dailyTransactions[dateKey] ?? [];
      return sum +
          transactions
              .where((tx) => tx.status == TransactionStatus.success)
              .length;
    });
    final totalFailed = dateKeys.fold<int>(0, (sum, dateKey) {
      final transactions = dailyTransactions[dateKey] ?? [];
      return sum +
          transactions
              .where((tx) => tx.status != TransactionStatus.success)
              .length;
    });

    final rawMaxY = maxTransactionsPerDay(
      dateKeys,
      dailyTransactions,
    ).toDouble();
    final yInterval = calculateNiceInterval(rawMaxY);
    final chartMaxY = roundUpMaxY(rawMaxY, yInterval);

    return SizedBox(
      height: 260,
      child: Column(
        children: [
          TransactionSummaryHeader(
            totalSuccess: totalSuccess,
            totalFailed: totalFailed,
          ),
          TransactionChartLegend(),

          // Chart
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double groupWidth = 48; // width per day group
                final double chartWidth = max(
                  constraints.maxWidth,
                  dateKeys.length * groupWidth,
                );
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: totalDays.toDouble()),
                      duration: const Duration(milliseconds: 3000),
                      curve: Curves.easeOutBack,
                      builder: (context, progress, child) {
                        final currentDay = progress.floor().clamp(
                          0,
                          totalDays - 1,
                        );

                        final animatedSuccessSpots = successSpots
                            .asMap()
                            .entries
                            .map((e) {
                              return e.key <= currentDay
                                  ? e.value
                                  : FlSpot(e.value.x, 0);
                            })
                            .toList();

                        final animatedFailedSpots = failedSpots
                            .asMap()
                            .entries
                            .map((e) {
                              return e.key <= currentDay
                                  ? e.value
                                  : FlSpot(e.value.x, 0);
                            })
                            .toList();

                        return LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: yInterval,
                              drawVerticalLine: false,
                              checkToShowHorizontalLine: (value) =>
                                  value % yInterval == 0,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Theme.of(context).dividerColor,
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: yInterval,
                                  getTitlesWidget: (value, meta) {
                                    final intLabel = value.toInt();
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: Text(
                                        '$intLabel',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < dateKeys.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          _getDateLabel(index),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                top: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                  width: 1.2,
                                ),
                                bottom: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                  width: 1.2,
                                ),
                                left: BorderSide.none,
                                right: BorderSide.none,
                              ),
                            ),
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (touchedSpot) =>
                                    touchedSpot.barIndex == 0
                                    ? Colors.green.shade700
                                    : Colors.red.shade800,
                                tooltipRoundedRadius: 16,
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                tooltipPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                tooltipMargin: 12,
                                maxContentWidth: 120,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots
                                      .map((barSpot) {
                                        final dayIndex = barSpot.spotIndex;
                                        if (dayIndex >= dateKeys.length)
                                          return null;

                                        final dateKey = dateKeys[dayIndex];
                                        final transactions =
                                            dailyTransactions[dateKey] ?? [];
                                        final isSuccess = barSpot.barIndex == 0;

                                        String tooltipText;
                                        if (isSuccess) {
                                          final successTxns = transactions
                                              .where(
                                                (tx) =>
                                                    tx.status ==
                                                    TransactionStatus.success,
                                              );
                                          final successAmount = successTxns
                                              .fold<double>(
                                                0,
                                                (sum, tx) => sum + tx.amount,
                                              );
                                          final count = successTxns.length;
                                          tooltipText =
                                              'SUCCESS\n$count transactions\n₹${(successAmount).toStringAsFixed(0)}';
                                        } else {
                                          final failedTxns = transactions.where(
                                            (tx) =>
                                                tx.status !=
                                                TransactionStatus.success,
                                          );
                                          final failedAmount = failedTxns
                                              .fold<double>(
                                                0,
                                                (sum, tx) => sum + tx.amount,
                                              );
                                          final count = failedTxns.length;

                                          tooltipText =
                                              'FAILED\n$count transactions\n₹${(failedAmount).toStringAsFixed(0)}';
                                        }

                                        return LineTooltipItem(
                                          tooltipText,
                                          const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            height: 1.4,
                                          ),
                                        );
                                      })
                                      .whereType<LineTooltipItem>()
                                      .toList();
                                },
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: animatedSuccessSpots,
                                isCurved: true,
                                preventCurveOverShooting: true,
                                curveSmoothness: 0.3,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade600,
                                    Colors.green.shade400,
                                  ],
                                ),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) =>
                                          FlDotCirclePainter(
                                            radius: spot.y > 2 ? 3 : 2,
                                            color: Colors.green,
                                            strokeWidth: 2,
                                            strokeColor: Colors.white,
                                          ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.withOpacity(0.2),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              LineChartBarData(
                                spots: animatedFailedSpots,
                                isCurved: true,
                                curveSmoothness: 0.3,
                                preventCurveOverShooting: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade600,
                                    Colors.red.shade400,
                                  ],
                                ),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) =>
                                          FlDotCirclePainter(
                                            radius: spot.y > 1 ? 3 : 2,
                                            color: Colors.red,
                                            strokeWidth: 2,
                                            strokeColor: Colors.white,
                                          ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.withOpacity(0.15),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            minX: 0,
                            maxX: (dateKeys.length - 1).toDouble(),
                            minY: 0,
                            maxY: chartMaxY,
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

  String _getDateLabel(int index) {
    if (index >= 0 && index < dateKeys.length) {
      return dateKeys[index]; // ✅ Already formatted as "MMM dd"
    }
    return '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
