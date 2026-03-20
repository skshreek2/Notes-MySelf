

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hdfc_merchant_app/core/util/common.dart';
import 'package:hdfc_merchant_app/features/payments/data/orders_entity.dart';

class StatusDistributionBarChart extends StatefulWidget{
  final double height;
  final List<TransactionEntity> orders;
  final String dateRange;

  const StatusDistributionBarChart({
    super.key,
    required this.height,
    required this.orders,
    required this.dateRange,
  });

 @override
  State<StatusDistributionBarChart> createState() => _StatusDistributionBarChartState();
}

class _StatusDistributionBarChartState extends State<StatusDistributionBarChart> with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _animation;
  int touchedStatusBarIndex = -1;
 

 @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: chartDuration);

    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) =>
      BarChartGroupData(
        x: x,
        barRods: [
          BarChartRodData(
            toY: y * _animation.value,
            color: color,
            width: 22,
            borderRadius: BorderRadius.circular(6),
             backDrawRodData: null,
             
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
   final colors = [
      Colors.green.shade700,
      Colors.orange.shade700,
      Colors.red.shade700,
    ];
    final statusLabels = ['Success', 'Pending', 'Failed'];
    final statusDistributionData = statusDistribution(widget.orders);

    final data = statusDistributionData.map((e) => e.clamp(0, 100)).toList();

    final barGroups = List.generate(
      statusDistributionData.length,
      (index) => _makeGroupData(
        index,
        statusDistributionData[index],
        colors[index],
      ),
    );

    return AnimatedBuilder(animation: _animation,
     builder: (context, child){
      return Container(
      height: widget.height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.topRight,
            child: Text(
              widget.dateRange,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: 100,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (response?.spot == null) {
                      setState(() => touchedStatusBarIndex = -1);
                      return;
                    }
                    setState(
                      () => touchedStatusBarIndex =
                          response!.spot!.touchedBarGroupIndex,
                    );
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) =>
                        colors[group.x.clamp(0, 2).toInt()],
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final value =
                          statusDistributionData[groupIndex.clamp(
                            0,
                            statusDistributionData.length - 1,
                          )];
                      return BarTooltipItem(
                        '${statusLabels[groupIndex]}\n${value.round()}%',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
               
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: const Padding(padding: const EdgeInsets.only(bottom: 8),
                    child: Text("Percentage", style: TextStyle(fontSize: 12),),),
                    
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 25,
                      getTitlesWidget: (value, meta){
                        return Text('${(value.toInt())}%',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),);
                      },
                    )
                  ),

                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(padding: const EdgeInsets.only(top: 6),
                              child: Text(statusLabels[value.toInt()],
                              style: const TextStyle(fontSize: 12),
                              ),
                          );
                        }
                      ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)
                  )
                ),

                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
     },);
  }
  
}
