import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hdfc_merchant_app/core/util/common.dart';
import 'package:hdfc_merchant_app/features/dashboard/presentation/graphs/y_axis_labels.dart';
import 'package:hdfc_merchant_app/features/dashboard/ui/widgets/transaction_chart_legend.dart';
import 'package:hdfc_merchant_app/features/dashboard/ui/widgets/transaction_summary_header.dart';
import 'package:intl/intl.dart';
import 'package:hdfc_merchant_app/features/payments/data/orders_entity.dart';

import '../../../../core/util/gif_progressbar.dart';

class DetailedTransactionBarChart extends StatefulWidget {
  final List<TransactionEntity> orders;
  final Map<String, double> dailyData;
  final DateTime? startDate;
  final DateTime? endDate;

  // ✅ Updated to accept String keys

  const DetailedTransactionBarChart({
    super.key,
    required this.orders,
    required this.dailyData,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<DetailedTransactionBarChart> createState() =>
      _DetailedTransactionBarChartState();
}

class _DetailedTransactionBarChartState
    extends State<DetailedTransactionBarChart>
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
  void didUpdateWidget(DetailedTransactionBarChart oldWidget) {
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
          .where((tx) => tx.status == TransactionStatus.failed)
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
              .where((tx) => tx.status == TransactionStatus.failed)
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
          // Expanded(
          //   child: Row(
          //     crossAxisAlignment: CrossAxisAlignment.stretch,
          //     children: [
          //       SizedBox(
          //         width: 40,
          //         child: YAxisLabels(maxY: chartMaxY, interval: yInterval),
          //       ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double groupWidth = 48;
                final double chartWidth = max(
                  constraints.maxWidth,
                  dateKeys.length * groupWidth,
                );
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 3000),
                      curve: Curves.easeOutBack,
                      builder: (context, progress, child) {
                        final currentDay = (progress * totalDays).floor().clamp(
                          0,
                          totalDays - 1,
                        );

                        final barGroups = List.generate(dateKeys.length, (
                          index,
                        ) {
                          if (index > currentDay) {
                            // Animate to zero height
                            return BarChartGroupData(
                              x: index,

                              barRods: [
                                BarChartRodData(
                                  toY: 0,
                                  width: 20,
                                  color: Colors.green.shade600,
                                ),
                                BarChartRodData(
                                  toY: 0,
                                  width: 20,
                                  color: Colors.red.shade600,
                                ),
                              ],
                            );
                          }
                          const double minVisibleBarHeight = 0.001;
                          // Live data
                          final transactions =
                              dailyTransactions[dateKeys[index]] ?? [];
                          final successCount = transactions
                              .where(
                                (tx) => tx.status == TransactionStatus.success,
                              )
                              .length;
                          final failedCount = transactions
                              .where(
                                (tx) => tx.status == TransactionStatus.failed,
                              )
                              .length;
                          final totalCount = successCount + failedCount;

                          final successisZero = successCount == 0;
                          final successdisplayValue = successisZero
                              ? minVisibleBarHeight
                              : successCount.toDouble();
                          final successbarWidth = successisZero ? 15.0 : 20.0;

                          final failedisZero = failedCount == 0;
                          final faileddisplayValue = failedisZero
                              ? minVisibleBarHeight
                              : failedCount.toDouble();
                          final failedbarWidth = failedisZero ? 15.0 : 20.0;

                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: successdisplayValue,
                                width: successbarWidth,
                                color: successisZero
                                    ? Colors.green.withValues(alpha: 1)
                                    : Colors.green.shade600,
                                borderRadius: BorderRadius.circular(
                                  successisZero ? 1 : 6,
                                ),
                              ),
                              BarChartRodData(
                                toY: faileddisplayValue,
                                width: failedbarWidth,
                                color: failedisZero
                                    ? Colors.red.withValues(alpha: 1)
                                    : Colors.red.shade600,
                                borderRadius: BorderRadius.circular(
                                  failedisZero ? 1 : 6,
                                ),
                              ),
                            ],
                          );
                        });

                        return BarChart(
                          BarChartData(
                            barGroups: barGroups,
                            alignment: BarChartAlignment.spaceAround,
                            maxY: chartMaxY,
                            baselineY: 0,
                            minY: 0,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => Theme.of(
                                  context,
                                ).colorScheme.inverseSurface,
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                tooltipRoundedRadius: 12,
                                tooltipPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                tooltipMargin: 5,
                                maxContentWidth: 120,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final dayIndex = group.x.toInt();
                                  if (dayIndex >= dateKeys.length) {
                                    return null;
                                  }

                                  final dateKey = dateKeys[dayIndex];
                                  final transactions =
                                      dailyTransactions[dateKey] ?? [];
                                  final isSuccess =
                                      rodIndex ==
                                      0; // 0=success (green), 1=failed (red)

                                  String tooltipText;
                                  if (isSuccess) {
                                    final successTxns = transactions.where(
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
                                        'SUCCESS\n$count txns\n₹${(successAmount).toStringAsFixed(0)}';
                                  } else {
                                    final failedTxns = transactions.where(
                                      (tx) =>
                                          tx.status == TransactionStatus.failed,
                                    );
                                    final failedAmount = failedTxns
                                        .fold<double>(
                                          0,
                                          (sum, tx) => sum + tx.amount,
                                        );
                                    final count = failedTxns.length;
                                    tooltipText =
                                        'FAILED\n$count txns\n₹${(failedAmount).toStringAsFixed(0)}';
                                  }

                                  return BarTooltipItem(
                                    tooltipText,
                                    const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.4,
                                    ),
                                  );
                                },
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: yInterval,
                              // checkToShowHorizontalLine: (value) =>
                              //     value % yInterval == 0,
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
                                    // if (intLabel == 0) return const SizedBox.shrink();
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
                                  reservedSize: 24,
                                  interval: null,
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
                                  width: 1,
                                ),
                                bottom: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                  width: 1,
                                ),
                                left: BorderSide.none,
                                right: BorderSide.none,
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
          //],
          // ),
          //),
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
