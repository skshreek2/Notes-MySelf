import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartPage extends StatelessWidget {
  const PieChartPage({super.key});

  final List<ChartItem> items = const [
    ChartItem(value: 13, color: Color(0xFF79A6F5), label: '13%'),
    ChartItem(value: 28, color: Color(0xFF215FCB), label: '28%'),
    ChartItem(value: 36, color: Color(0xFF1E4EA8), label: '36%'),
    ChartItem(value: 16, color: Color(0xFF2F69CC), label: '16%'),
    // ChartItem(value: 12, color: Color.fromARGB(255, 51, 96, 163), label: '12%'),
  ];

  @override
  Widget build(BuildContext context) {
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
    final total = items.fold<double>(0, (sum, item) => sum + item.value);

    return items.map((item) {
      return PieChartSectionData(
        value: item.value,
        color: item.color,
        radius: 75,
        title: '',
        showTitle: false,
        badgeWidget: PercentBadge(label: item.label),
        badgePositionPercentageOffset: 0.97,
      );
    }).toList();
  }

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
