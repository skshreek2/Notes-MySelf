class DateRange {
  final String fromDate;
  final String toDate;

  DateRange({
    required this.fromDate,
    required this.toDate,
  });
}

import 'package:intl/intl.dart';

DateRange _getDateRange(String filter) {
  final now = DateTime.now();
  final formatter = DateFormat('yyyy-MM-dd');

  switch (filter) {
    case 'Yesterday':
      final yesterday = now.subtract(const Duration(days: 1));
      return DateRange(
        fromDate: formatter.format(yesterday),
        toDate: formatter.format(yesterday),
      );

    case 'Today':
      return DateRange(
        fromDate: formatter.format(now),
        toDate: formatter.format(now),
      );

    case 'Weekly': // Last 7 Days
      return DateRange(
        fromDate: formatter.format(now.subtract(const Duration(days: 6))),
        toDate: formatter.format(now),
      );

    case 'Monthly': // Last 30 Days
      return DateRange(
        fromDate: formatter.format(now.subtract(const Duration(days: 29))),
        toDate: formatter.format(now),
      );

    default:
      return DateRange(
        fromDate: formatter.format(now),
        toDate: formatter.format(now),
      );
  }
}
