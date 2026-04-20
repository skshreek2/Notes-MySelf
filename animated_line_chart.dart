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
  final Map<String, double> dailyData;
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
      DateTime current = widget.startDate!;
      final end = widget.endDate!;

      while (!current.isAfter(end)) {
        final dateStr = dateFormat.format(current);
        parsedData[dateStr] = [];
        current = current.add(const Duration(days: 1));
      }
    }

    for (final transaction in widget.orders) {
      final dateStr = DateFormat('MMM dd').format(transaction.date);
      parsedData.putIfAbsent(dateStr, () => []).add(transaction);
    }

    dateKeys = parsedData.keys.toList()
      ..sort((a, b) {
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

  String formatNumber(double val) {
    if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(1)}K';
    }
    return val.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (widget.orders.isEmpty ||
        !isDataReady ||
        dateKeys.isEmpty ||
        successSpots.isEmpty ||
        failedSpots.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(child: GifProgressBar()),
      );
    }

    final totalDays = dateKeys.length;

    final totalSuccess = dateKeys.fold<int>(0, (sum, dateKey) {
      final tx = dailyTransactions[dateKey] ?? [];
      return sum +
          tx.where((t) => t.status == TransactionStatus.success).length;
    });

    final totalFailed = dateKeys.fold<int>(0, (sum, dateKey) {
      final tx = dailyTransactions[dateKey] ?? [];
      return sum +
          tx.where((t) => t.status != TransactionStatus.success).length;
    });

    final rawMaxY =
        maxTransactionsPerDay(dateKeys, dailyTransactions).toDouble();

    final yInterval = calculateNiceInterval(rawMaxY);
    final chartMaxY = roundUpMaxY(rawMaxY, yInterval);

    return SizedBox(
      height: isMobile ? 280 : 260,
      child: Column(
        children: [
          TransactionSummaryHeader(
            totalSuccess: totalSuccess,
            totalFailed: totalFailed,
          ),
          TransactionChartLegend(),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double groupWidth = isMobile ? 36 : 48;

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
                        final currentDay =
                            progress.floor().clamp(0, totalDays - 1);

                        final animatedSuccessSpots = successSpots
                            .asMap()
                            .entries
                            .map((e) => e.key <= currentDay
                                ? e.value
                                : FlSpot(e.value.x, 0))
                            .toList();

                        final animatedFailedSpots = failedSpots
                            .asMap()
                            .entries
                            .map((e) => e.key <= currentDay
                                ? e.value
                                : FlSpot(e.value.x, 0))
                            .toList();

                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: LineChart(
                            LineChartData(
                              minX: 0,
                              maxX: (dateKeys.length - 1).toDouble(),
                              minY: 0,
                              maxY: chartMaxY,

                              gridData: FlGridData(
                                show: true,
                                horizontalInterval: yInterval,
                                drawVerticalLine: false,
                                checkToShowHorizontalLine: (value) =>
                                    value % yInterval == 0,
                              ),

                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 55,
                                    interval: yInterval,
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 6),
                                        child: Text(
                                          formatNumber(value),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: isMobile ? 2 : 1,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= 0 &&
                                          index < dateKeys.length) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            dateKeys[index],
                                            style: TextStyle(
                                              fontSize:
                                                  isMobile ? 9 : 10,
                                              fontWeight: FontWeight.w600,
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
                                  top: BorderSide(width: 1.2),
                                  bottom: BorderSide(width: 1.2),
                                ),
                              ),

                              lineBarsData: [
                                LineChartBarData(
                                  spots: animatedSuccessSpots,
                                  isCurved: true,
                                  barWidth: 3,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade600,
                                      Colors.green.shade400,
                                    ],
                                  ),
                                ),
                                LineChartBarData(
                                  spots: animatedFailedSpots,
                                  isCurved: true,
                                  barWidth: 3,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.shade600,
                                      Colors.red.shade400,
                                    ],
                                  ),
                                ),
                              ],
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
