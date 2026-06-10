
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
  // static const _entries = <HorizontalBarEntry>[
  //   HorizontalBarEntry(label: 'UPI', value: 114, valueLabel: '₹114'),
  //   HorizontalBarEntry(label: 'Credit Card', value: 128, valueLabel: '₹128'),
  //   HorizontalBarEntry(label: 'Debit Card', value: 235, valueLabel: '₹235'),
  //   HorizontalBarEntry(label: 'Net Banking', value: 120, valueLabel: '₹120'),
  //   HorizontalBarEntry(label: 'Wallets', value: 305, valueLabel: '₹305'),
  // ];

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
        value: e.amount.toDouble(),
        valueLabel: compactFormatter.format(e.amount),
      );
    }).toList();

    final maxAmount = widget.paymentvolume
        .map((e) => e.amount.toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Container(
      child: Expanded(
        child: DynamicHorizontalBarChart(
          key: ValueKey(_chartGeneration),
          entries: entries,
          maxY: maxAmount * 1.15,
          valueFormatter: (v) => compactFormatter.format(v),
        ),
      ),
    );
  }

  static String _trim(double v) {
    var s = v.toStringAsFixed(2);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
    return s;
  }
}
