import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/data/payment_response_model.dart';

class PieChartPage extends StatelessWidget {
  List<PaymentMethodDistributionModel> paymentMethodDistribution;
  PieChartPage({super.key, required this.paymentMethodDistribution});

  final List<Color> chartColors = const [
    Color(0xFF79A6F5),
    Color(0xFF215FCB),
    Color(0xFF1E4EA8),
    Color(0xFF2F69CC),
    Color(0xFF5B8DEF),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (paymentMethodDistribution.isEmpty) {
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
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 192,
          height: 192,
          child: PieChart(
            PieChartData(
              startDegreeOffset: 90,
              sectionsSpace: 0,
              centerSpaceRadius: 60,
              borderData: FlBorderData(show: false),
              sections: _buildSections(),
            ),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return List.generate(paymentMethodDistribution.length, (index) {
      final item = paymentMethodDistribution[index];
      final percentage = item.percentage;
      final isSmall = percentage <= 7.0;
      final total = paymentMethodDistribution.fold(
        0.0,
        (sum, item) => sum + percentage,
      );

      print("Total $total");

      return PieChartSectionData(
        value: percentage,
        color: chartColors[index % chartColors.length],
        radius: 75,
        // title: isSmall ? '' : '${percentage.toStringAsFixed(1)}%',
        titleStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isSmall ? 10 : 12,
        ),
        titlePositionPercentageOffset: 0.62,
        // badgeWidget: isSmall
        //     ? Transform.rotate(
        //         angle: -1.57,
        //         child: Text(
        //           '${percentage.toStringAsFixed(1)}%',
        //           style: const TextStyle(
        //             color: Colors.white,
        //             fontWeight: FontWeight.bold,
        //             fontSize: 10,
        //           ),
        //         ),
        //       )
        //     : null,
        badgeWidget: PercentBadge(
          label: '${item.percentage.toStringAsFixed(1)}%',
        ),
        badgePositionPercentageOffset: _badgeOffset(
          value: item.percentage,
          total: total,
        ),
      );
    });
  }
  // List<PieChartSectionData> _buildSections() {
  //   return List.generate(paymentMethodDistribution.length, (index) {
  //     final item = paymentMethodDistribution[index];
  //     final percentage = item.percentage;
  //     final isSmall = percentage <= 8.0;
  //     return PieChartSectionData(
  //       value: percentage,
  //       color: chartColors[index % chartColors.length],

  //       radius: 75,
  //       title: '${item.percentage.toStringAsFixed(1)}%',
  //       titleStyle: TextStyle(
  //         color: Colors.white,
  //         fontWeight: FontWeight.bold,
  //         fontSize: isSmall ? 10 : 12,
  //       ),
  //       titlePositionPercentageOffset: isSmall ? 0.82 : 0.62,
  //       titleSunbeamLayout: isSmall,
  //     );
  //   });
  // }

  double _badgeOffset({required double value, required double total}) {
    final percent = value / total;

    const minOffset = 0.74;
    const maxOffset = 0.92;

    final offset = maxOffset - (percent * 0.35);
    return offset.clamp(minOffset, maxOffset);
  }
}

class PercentBadge extends StatelessWidget {
  final String label;

  const PercentBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class ChartItem {
  final double value;
  final Color color;
  final String label;

  const ChartItem({
    required this.value,
    required this.color,
    required this.label,
  });
}
