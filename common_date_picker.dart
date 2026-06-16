import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

enum PickerMode {
  day,
  dateRange,
  month,
  monthRange,
}

class CommonDatePicker extends StatefulWidget {
  const CommonDatePicker({
    super.key,
    required this.onApply,
  });

  final Function(String value, Object? rawValue) onApply;

  @override
  State<CommonDatePicker> createState() => _CommonDatePickerState();
}

class _CommonDatePickerState extends State<CommonDatePicker> {
  final DateRangePickerController _controller =
      DateRangePickerController();

  PickerMode _mode = PickerMode.day;

  Object? _selectedValue;

  @override
  void initState() {
    super.initState();
    _updateView();
  }

  void _updateView() {
    if (_mode == PickerMode.month ||
        _mode == PickerMode.monthRange) {
      _controller.view = DateRangePickerView.year;
    } else {
      _controller.view = DateRangePickerView.month;
    }
  }

  DateRangePickerSelectionMode get _selectionMode {
    switch (_mode) {
      case PickerMode.day:
      case PickerMode.month:
        return DateRangePickerSelectionMode.single;

      case PickerMode.dateRange:
      case PickerMode.monthRange:
        return DateRangePickerSelectionMode.range;
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthName(date.month)} '
        '${date.year}';
  }

  String _formatMonth(DateTime date) {
    return '${_monthName(date.month)} ${date.year}';
  }

  DateTime get _today => DateTime.now();

DateTime _monthStart(DateTime date) {
  return DateTime(date.year, date.month, 1);
}

DateTime _monthEnd(DateTime date) {
  final now = _today;

  // current month
  if (date.year == now.year &&
      date.month == now.month) {
    return now;
  }

  return DateTime(
    date.year,
    date.month + 1,
    0,
  );
}

  String get displayText {
    if (_selectedValue == null) {
      return 'No Selection';
    }

    switch (_mode) {
      case PickerMode.day:
        return _formatDate(_selectedValue as DateTime);

      case PickerMode.month:
        final date = _selectedValue as DateTime;

        final start = _monthStart(date);
        final end = _monthEnd(date);

  return '${_formatDate(start)} - ${_formatDate(end)}';

      case PickerMode.dateRange:
        final range = _selectedValue as PickerDateRange;

        return '${_formatDate(range.startDate!)}'
            ' - '
            '${_formatDate(range.endDate ?? range.startDate!)}';

      case PickerMode.monthRange:
        final range = _selectedValue as PickerDateRange;

  final start =
      _monthStart(range.startDate!);

  final end =
      _monthEnd(range.endDate ?? range.startDate!);

  return '${_formatDate(start)}'
      ' - '
      '${_formatDate(end)}';
    }
  }

  void _apply() {
   if (_selectedValue == null) return;

  if (_mode == PickerMode.month) {
    final selected = _selectedValue as DateTime;

    widget.onApply(
      '${_formatDate(_monthStart(selected))}'
      ' - '
      '${_formatDate(_monthEnd(selected))}',
      {
        'startDate': _monthStart(selected),
        'endDate': _monthEnd(selected),
      },
    );
    return;
  }

  if (_mode == PickerMode.monthRange) {
    final range = _selectedValue as PickerDateRange;

    final start =
        _monthStart(range.startDate!);

    final end =
        _monthEnd(
          range.endDate ?? range.startDate!,
        );

    widget.onApply(
      '${_formatDate(start)} - ${_formatDate(end)}',
      {
        'startDate': start,
        'endDate': end,
      },
    );
    return;
  }

  widget.onApply(
    displayText,
    _selectedValue,
  );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(24),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<PickerMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: PickerMode.day,
                  label: Text('Date'),
                  icon: Icon(Icons.today),
                ),
                ButtonSegment(
                  value: PickerMode.dateRange,
                  label: Text('Range'),
                  icon: Icon(Icons.date_range),
                ),
                ButtonSegment(
                  value: PickerMode.month,
                  label: Text('Month'),
                  icon: Icon(Icons.calendar_view_month),
                ),
                ButtonSegment(
                  value: PickerMode.monthRange,
                  label: Text('Month Range'),
                  icon: Icon(Icons.view_module),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (value) {
                setState(() {
                  _mode = value.first;
                  _selectedValue = null;
                  _updateView();
                });
              },
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xffF5F7FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                displayText,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),

            SfDateRangePicker(
              controller: _controller,
              maxDate: DateTime.now(),
              view: (_mode == PickerMode.month ||
                      _mode == PickerMode.monthRange)
                  ? DateRangePickerView.year
                  : DateRangePickerView.month,

              selectionMode: _selectionMode,

              allowViewNavigation:
                  _mode == PickerMode.day ||
                      _mode == PickerMode.dateRange,

              onSelectionChanged:
                  (DateRangePickerSelectionChangedArgs args) {
                setState(() {
                  _selectedValue = args.value;
                });
              },

              selectionColor: Colors.blue,
              startRangeSelectionColor: Colors.blue,
              endRangeSelectionColor: Colors.blue,
              rangeSelectionColor:
                  Colors.blue.withOpacity(.15),

              headerStyle:
                  const DateRangePickerHeaderStyle(
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
