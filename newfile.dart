import 'package:intl/intl.dart';

class DateRange {
  final String fromDate;
  final String toDate;

  const DateRange({
    required this.fromDate,
    required this.toDate,
  });
}

class DateRangeHelper {
  static final DateFormat _formatter = DateFormat('yyyy-MM-dd');

  static DateRange getDateRange(String filter) {
    final now = DateTime.now();

    switch (filter) {
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        return DateRange(
          fromDate: _formatter.format(yesterday),
          toDate: _formatter.format(yesterday),
        );

      case 'Today':
        return DateRange(
          fromDate: _formatter.format(now),
          toDate: _formatter.format(now),
        );

      case 'Weekly': // Last 7 Days
        return DateRange(
          fromDate: _formatter.format(
            now.subtract(const Duration(days: 6)),
          ),
          toDate: _formatter.format(now),
        );

      case 'Monthly': // Last 30 Days
        return DateRange(
          fromDate: _formatter.format(
            now.subtract(const Duration(days: 29)),
          ),
          toDate: _formatter.format(now),
        );

      default:
        return DateRange(
          fromDate: _formatter.format(now),
          toDate: _formatter.format(now),
        );
    }
  }
}
