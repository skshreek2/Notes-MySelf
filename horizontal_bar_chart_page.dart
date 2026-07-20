import 'dart:math' as math show sqrt;

import 'package:hdfc_merchant_app/features/dashboard_amps/data/payment_response_model.dart';
import 'package:intl/intl.dart';

import 'dynamic_horizontal_ bar_chart.dart';
import 'package:flutter/material.dart';

/// Demo screen for [DynamicHorizontalBarChart].
class HorizontalBarChartPage extends StatefulWidget {
  final List<PaymentMethodVolumeModel> paymentvolume;
  const HorizontalBarChartPage({super.key, required this.paymentvolume});

  @override
  State<HorizontalBarChartPage> createState() => _HorizontalBarChartPageState();
}

class _HorizontalBarChartPageState extends State<HorizontalBarChartPage> {
  int _chartGeneration = 0;

  void _replay() => setState(() => _chartGeneration++);

  final NumberFormat compactFormatter = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (widget.paymentvolume.isEmpty) {
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

    final entries = widget.paymentvolume.map((e) {
      return HorizontalBarEntry(
        label: e.paymentMethodName,
        value: math.sqrt(e.amount),
        valueLabel: compactFormatter.format(e.amount),
        sqrtval: math.sqrt(e.amount),
      );
    }).toList();

    final maxAmount = widget.paymentvolume
        .map((e) => math.sqrt(e.amount))
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 260,
      width: double.infinity,
      child: DynamicHorizontalBarChart(
        key: ValueKey(_chartGeneration),
        entries: entries,
        maxY: maxAmount * 1.15,
        valueFormatter: (v) => compactFormatter.format(v),
      ),
    );
  }
}
