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
        IconButton(
         onPressed: () => onToggle (1 - currentType),
         icon: Icon(currentType == 0 ? Icons.show_chart : Icons.bar_chart,
         size: 28,
         color: Theme.of(context).textTheme.titleLarge?.color,),
         tooltip: currentType == 0 ? 'Switch to Line chart' : 'Switch to Bar chart',
         style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5)),
         padding: const EdgeInsets.all(8),
         )

        // Container(
        //   padding: const EdgeInsets.all(4),
        //   decoration: BoxDecoration(
        //     color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        //     borderRadius: BorderRadius.circular(12),  
        //   ),
        //   child:  Row(
        //     children: [
        //       _buildToggleIcon(context, icon: Icons.bar_chart, isSelected: currentType == 1, onTap: () => onToggle(1)),
        //       _buildToggleIcon(context, icon: Icons.show_chart, isSelected: currentType == 0, onTap: () => onToggle(0)),
              
        //     ],
        //   ),
        // )
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

Widget _buildToggleIcon(BuildContext context, {
  required IconData icon,
   required bool isSelected, 
   required VoidCallback onTap}){

  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 250),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, size: 22, color: isSelected ? Colors.white : Theme.of(context).textTheme.titleLarge?.color),
    ),

     
  );
}
