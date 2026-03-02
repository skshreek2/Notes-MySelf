import 'package:flutter/material.dart';

class WeeklyVolumeChart extends StatelessWidget {
final Widget child;
final String chartName;
final int currentType;
final Function(int) onToggle;

const WeeklyVolumeChart({
  super.key,
  required this.child,
  required this.chartName,
  required this.currentType,
  required this.onToggle,
});

  @override
  Widget build(BuildContext context) {
   return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 25,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          Text(
          chartName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        IconButton(onPressed: () => onToggle (1 - currentType),
         icon: Icon(currentType == 0 ? Icons.show_chart : Icons.bar_chart,
         size: 28,
         color: Theme.of(context).textTheme.titleLarge?.color,),
         tooltip: currentType == 0 ? 'Switch to Line chart' : 'Switch to Bar chart',
         style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5)),
         padding: const EdgeInsets.all(8),
         )
          ],
        ),
        
        const SizedBox(height: 24),
      //  Expanded(child: weeklyChart),
         SizedBox(
        height: 300,  // Fixed height for charts
        child: child,
      ),
      ],
    ),
  );
  }
  
}
