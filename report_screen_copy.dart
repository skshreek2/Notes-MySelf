import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hdfc_merchant_app/core/theme/app_theme.dart';
import 'package:hdfc_merchant_app/core/util/date_picker_service.dart';
import 'package:hdfc_merchant_app/core/util/gif_progressbar.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/utils/date_range.dart';
import 'package:hdfc_merchant_app/features/reports/bloc/reports_bloc.dart';
import 'package:hdfc_merchant_app/features/reports_amps/bloc/reports_event.dart';
import 'package:hdfc_merchant_app/features/reports_amps/bloc/reports_state.dart';
import 'package:hdfc_merchant_app/features/reports_amps/data/reports_model.dart';
import 'package:hdfc_merchant_app/features/reports_amps/data/reports_repository.dart';
import 'package:hdfc_merchant_app/features/shared/reports_searchbar.dart';
import 'package:hdfc_merchant_app/shared/calender/alendar_cubit.dart';
import 'package:hdfc_merchant_app/features/reports_amps/bloc/reports_bloc.dart';
import 'package:hdfc_merchant_app/shared/widgets/pagination_control.dart';
import 'schedule_reports_dialog.dart';
import 'package:intl/intl.dart' hide TextDirection;

const bool enableMprMergeDownload = true;

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final calendarState = context.read<CalendarCubit>().state;
        final bloc = ReportHistoryBloc(repository: ReportsRepository());
        print("start point");
        // if (calendarState.startDate != null && calendarState.endDate != null) {
        //   print("inside calendar state");
        //   bloc.add(
        //     ReportHistoryDateRangeChanged(
        //       fromDate: calendarState.startDate!.toIso8601String(),
        //       toDate: calendarState.endDate!.toIso8601String(),
        //     ),
        //   );
        // } else {
        print("else condtion state");
        final dateRange = DateRangeHelper.getDateRange('Today');
        final fromDate = dateRange.fromDate;
        final toDate = dateRange.toDate;

        bloc.add(ReportHistoryFetched(fromDate: fromDate, toDate: toDate));
        //  }
        print("end point");
        return bloc;
      },
      child: const ReportsView(),
    );
  }
}

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearchExpanded = false;
  late DateTimeRange _selectedDateRange;
  final _endDateController = TextEditingController();
  final _startDateController = TextEditingController();

  // String _selectedStatus = 'All Status';
  // String _selectedDaysFilter = 'Today';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 15)),
      end: now,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        context.read<ReportHistoryBloc>().add(
          ReportHistorySearchChanged(query),
        );
      }
    });
  }

  // void _openScheduleDialog(BuildContext context) {
  //   showGeneralDialog(
  //     context: context,
  //     barrierLabel: 'Schedule Reports',
  //     barrierDismissible: true,
  //     barrierColor: Colors.black54,
  //     transitionDuration: const Duration(milliseconds: 250),
  //     pageBuilder: (ctx, anim1, anim2) {
  //       return const SafeArea(
  //         child: Material(
  //           color: Colors.transparent,
  //           child: ScheduleReportsDialog(),
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CalendarCubit, CalendarState>(
      listener: (context, state) {
        if (state.startDate != null && state.endDate != null) {
          if (mounted) {
            setState(() {
              _selectedDateRange = DateTimeRange(
                start: state.startDate!,
                end: state.endDate!,
              );
            });

            context.read<ReportHistoryBloc>().add(
              ReportHistoryDateRangeChanged(
                fromDate: state.startDate!.toIso8601String(),
                toDate: state.endDate!.toIso8601String(),
              ),
            );
          }
        }
      },
      child: Container(
        color: const Color(0xFFEFF6FF),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            final padding = isMobile ? 16.0 : 48.0;

            return Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  _buildHeader(context, isMobile),
                  SizedBox(height: 18),
                  _buildGenerateReportCard(context, isMobile),
                  const SizedBox(height: 18),
                  _buildSearchAndFilters(context, isMobile),
                  const SizedBox(height: 18),
                  Expanded(child: _buildContent(context)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: GoogleFonts.dmSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF24366E),
                  height: 1.0,
                  letterSpacing: -0.68,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Generate and download comprehensive business reports',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B7280),
                  letterSpacing: -0.15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // ElevatedButton.icon(
        //   onPressed: () => _openScheduleDialog(context),
        //   label: const Text('Schedule Reports'),
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: const Color(0xFF2B50D9),
        //     foregroundColor: Colors.white,
        //     elevation: 0,
        //     padding: EdgeInsets.symmetric(
        //       horizontal: isMobile ? 16 : 22,
        //       vertical: isMobile ? 14 : 18,
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _buildGenerateReportCard(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.55), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.12),
            blurRadius: 10,
            spreadRadius: 0.5,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate New Report',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B233D),
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 20),
          isMobile
              ? Column(
                  children: [
                    // _buildFieldWithLabel(
                    //   label: 'Report Type',
                    //   child: _buildReportTypeDropdown(),
                    // ),
                    // const SizedBox(height: 16),
                    _buildFieldWithLabel(
                      label: 'Start Date',
                      child: _buildDateField('01/04/2026'),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldWithLabel(
                      label: 'End Date',
                      child: _buildDateField('29/04/2026'),
                    ),
                    const SizedBox(height: 16),
                    _reportActionButton(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildDatePickerField(
                        label: 'Start Date',
                        hint: 'DD/MM/YYYY',
                        context: context,
                        controller: _startDateController,
                        isStartDate: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDatePickerField(
                        label: 'End Date',
                        hint: 'DD/MM/YYYY',
                        context: context,
                        controller: _endDateController,
                        isStartDate: false,
                        startDateController: _startDateController,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: _reportActionButton(),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildFieldWithLabel({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 10),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E2A5A),
              letterSpacing: -0.15,
            ),
          ),
        ),
        const SizedBox(height: 3),
        child,
      ],
    );
  }

  Widget _buildReportTypeDropdown() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF7)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: 'Transaction Report',
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E2A5A),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Transaction Report',
              child: Text('Transaction Report'),
            ),
            DropdownMenuItem(
              value: 'Sales Report',
              child: Text('Sales Report'),
            ),
          ],
          onChanged: (_) {},
        ),
      ),
    );
  }

  Widget _buildDateField(String value) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E2A5A),
              ),
            ),
          ),
          const Icon(Icons.calendar_month_outlined, size: 20),
        ],
      ),
    );
  }

  Widget _reportActionButton() {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: () {
          final calendarState = context.read<CalendarCubit>().state;
          final formatter = DateFormat('yyyy-MM-dd');
          if (calendarState.startDate != null &&
              calendarState.endDate != null) {
            context.read<ReportHistoryBloc>().add(
              GenerateNewReport(
                fromDate: formatter.format(calendarState.startDate!),
                toDate: formatter.format(calendarState.endDate!),
              ),
            );
          }
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2B50D9)),
          foregroundColor: const Color(0xFF2B50D9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Text(
          'Generate Report',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2B50D9),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, bool isMobile) {
    return BlocBuilder<ReportHistoryBloc, ReportHistoryState>(
      builder: (context, state) {
        final loaded = state is ReportHistoryPaginationLoaded ? state : null;
        final List<String> daysFilters = [
          'Today',
          'Yesterday',
          'Last 7 Days',
          'Last 15 Days',
          'Last 30 Days',
          'Last 90 Days',
        ];

        final List<String> statusFilters = [
          'All Status',
          'Pending',
          'Failed',
          'Ready',
        ];
        final bloc = context.watch<ReportHistoryBloc>();

        final searchField = ReportsSearchBar(onChanged: _onSearchChanged);
        final statusDropdown = Container(
          width: isMobile ? double.infinity : 160,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.merchantCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.merchantBorder, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),

          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: statusFilters.contains(bloc.selectedStatus)
                  ? bloc.selectedStatus
                  : statusFilters.first,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0x66000000),
              ),
              isExpanded: true,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              dropdownColor: Theme.of(context).cardColor,
              onChanged: (value) {
                if (value == null) return;
                // setState(() {
                //   _selectedStatus = value;
                // });
                context.read<ReportHistoryBloc>().add(
                  ReportHistoryStatusChanged(value),
                );
              },
              items: statusFilters
                  .map(
                    (filter) => DropdownMenuItem<String>(
                      value: filter,
                      child: Text(filter),
                    ),
                  )
                  .toList(),
            ),
          ),
        );

        // final daysDropdown = Container(
        //   width: isMobile ? double.infinity : 160,
        //   height: 46,
        //   decoration: BoxDecoration(
        //     color: AppTheme.merchantCardBg,
        //     borderRadius: BorderRadius.circular(16),
        //     border: Border.all(color: AppTheme.merchantBorder, width: 2),
        //   ),
        //   padding: const EdgeInsets.symmetric(horizontal: 12),
        //   child: DropdownButtonHideUnderline(
        //     child: DropdownButton<String>(
        //       value: daysFilters.contains(bloc.selectedDaysFilter)
        //           ? bloc.selectedDaysFilter
        //           : daysFilters.first,
        //       icon: const Icon(
        //         Icons.keyboard_arrow_down_rounded,
        //         color: Color(0x66000000),
        //       ),
        //       isExpanded: true,
        //       style: TextStyle(
        //         fontFamily: 'Inter',
        //         fontWeight: FontWeight.w500,
        //         fontSize: 13,
        //         color: Theme.of(context).textTheme.bodyLarge?.color,
        //       ),
        //       dropdownColor: Theme.of(context).cardColor,
        //       onChanged: (value) {
        //         if (value == null) return;
        //         // setState(() {
        //         //   _selectedDaysFilter = value;
        //         // });

        //         final dateRange = DateRangeHelper.getDateRange(value);
        //         final fromDate = dateRange.fromDate;
        //         final toDate = dateRange.toDate;

        //         context.read<ReportHistoryBloc>().add(
        //           ReportHistoryDateRangeChanged(
        //             fromDate: fromDate,
        //             toDate: toDate,
        //             timeFrame: value,
        //           ),
        //         );
        //       },
        //       items: daysFilters
        //           .map(
        //             (filter) => DropdownMenuItem<String>(
        //               value: filter,
        //               child: Text(filter),
        //             ),
        //           )
        //           .toList(),
        //     ),
        //   ),
        // );
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: statusDropdown),
                  const SizedBox(width: 12),
                  // Expanded(child: daysDropdown),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 12),
            statusDropdown,
            const SizedBox(width: 12),
            // daysDropdown,
          ],
        );
      },
    );
  }

  Widget _buildFilterDropdown({
    required String title,
    required List<String> items,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF7)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E2A5A),
          ),
          dropdownColor: Colors.white,
          items: items
              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 3),
      child: BlocConsumer<ReportHistoryBloc, ReportHistoryState>(
        listener: (context, state) {
          if (state is ReportHistoryFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is GenerateReportLoaded) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Report Generation Request'),
                  content: const Text(
                    'Your report generation request has been submitted successfully.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }

          if (state is DownloadReportLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Report downloaded successfully",
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ReportHistoryLoading) {
            return GifProgressBar();
          } else if (state is ReportHistoryPaginationLoaded) {
            return _ReportsTablePaginated(
              reports: state.reports,
              metaInfo: int.tryParse(state.totalElements ?? '') ?? 0,
              currentPage: state.currentPage,
              totalPages: state.totalPages,
              rowsPerPage: state.rowsPerPage,
            );
          } else if (state is DownloadReportLoading) {
            return _ReportsTablePaginated(
              reports: state.prevreportState.reports,
              metaInfo:
                  int.tryParse(state.prevreportState.totalElements ?? '') ?? 0,
              currentPage: state.prevreportState.currentPage,
              totalPages: state.prevreportState.totalPages,
              rowsPerPage: state.prevreportState.rowsPerPage,
            );
          } else if (state is DownloadReportLoaded) {
            return _ReportsTablePaginated(
              reports: state.prevreportState.reports,
              metaInfo:
                  int.tryParse(state.prevreportState.totalElements ?? '') ?? 0,
              currentPage: state.prevreportState.currentPage,
              totalPages: state.prevreportState.totalPages,
              rowsPerPage: state.prevreportState.rowsPerPage,
            );
          } else if (state is ReportHistoryFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: AppTheme.merchantIconGrey,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Refunds'));
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) => Card(
    child: SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No reports matching your search',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.merchantTextGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                context.read<ReportHistoryBloc>().add(
                  ReportHistorySearchChanged(''),
                );
              },
              child: Text('Clear Search'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildErrorState(BuildContext context, String message) => Card(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/error_illustration.svg',
              height: 200,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            // const SizedBox(height: 24),
            // ElevatedButton.icon(
            //   onPressed: () => context.read<ReportsBloc>().add(ReportsFetched()),
            //   icon: const Icon(Icons.refresh),
            //   label: Text('Try Again'),
            //   style: ElevatedButton.styleFrom(
            //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(30),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    ),
  );
}

class _ReportsTablePaginated extends StatelessWidget {
  final List<ReportEntity> reports;
  final int metaInfo;
  final int currentPage;
  final int totalPages;
  final int rowsPerPage;

  const _ReportsTablePaginated({
    required this.reports,
    required this.metaInfo,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: ReportsTable(reports: reports)),
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: PaginationControl(
            currentPage: currentPage,
            totalPages: totalPages,
            totalRecords: metaInfo,
            rowsPerPage: rowsPerPage,
            onPageChanged: (page) {
              // context.read<ReportsBloc>().add(ReportsPageChanged(page));

              print("Page Changed $page");
              context.read<ReportHistoryBloc>().add(
                ReportHistoryPageChanged(page),
              );
            },
            onRowsPerPageChanged: (rows) {
              context.read<ReportHistoryBloc>().add(
                ReportHistoryRowsPerPageChanged(rows),
              );
            },
          ),
        ),
      ],
    );
  }
}

Widget _buildDatePickerField({
  required BuildContext context,
  required String label,
  required String hint,
  required TextEditingController controller,
  required bool isStartDate,
  TextEditingController? startDateController,
}) {
  final today = DateTime.now();
  final last180Days = today.subtract(const Duration(days: 180));

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: AppTheme.merchantNavy,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: AppTheme.merchantNavy,
        ),
        onTap: () async {
          DateTime? initialDate;
          DateTime? minDate;
          DateTime? maxDate;

          if (controller.text.isNotEmpty) {
            try {
              initialDate = DateFormat('dd/MM/yyyy').parse(controller.text);
            } catch (_) {}
          }

          if (isStartDate) {
            minDate = last180Days;
            maxDate = today;
          } else {
            DateTime? selectedStartDate;

            if (startDateController != null &&
                startDateController.text.isNotEmpty) {
              try {
                selectedStartDate = DateFormat(
                  'dd/MM/yyyy',
                ).parse(startDateController.text);
              } catch (_) {}
            }

            if (selectedStartDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select Start Date first')),
              );
              return;
            }

            minDate = selectedStartDate;
            maxDate = today;

            initialDate ??= selectedStartDate;

            if (initialDate.isBefore(minDate)) {
              initialDate = minDate;
            }
            if (initialDate.isAfter(maxDate)) {
              initialDate = maxDate;
            }
          }

          final pickedDate = await DatePickerService.showDatePickerReport(
            context: context,
            minDate: minDate,
            maxDate: maxDate,
            initialSelectedDate: initialDate,
            title: isStartDate ? 'Select Start Date' : 'Select End Date',
          );

          if (pickedDate != null) {
            final formatted = DateFormat('dd/MM/yyyy').format(pickedDate);
            controller.text = formatted;

            if (isStartDate) {
              if (_endDateController.text.isNotEmpty) {
                try {
                  final endDate = DateFormat(
                    'dd/MM/yyyy',
                  ).parse(_endDateController.text);
                  if (endDate.isBefore(pickedDate)) {
                    _endDateController.clear();
                  }
                } catch (_) {
                  _endDateController.clear();
                }
              }
            }
          }
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.merchantIconGrey),
          suffixIcon: const Icon(
            Icons.calendar_today_rounded,
            size: 18,
            color: AppTheme.merchantIconGrey,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.6),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppTheme.merchantAccent,
              width: 2,
            ),
          ),
        ),
      ),
    ],
  );
}
// Widget _buildDatePickerField({
//   required BuildContext context,
//   required String label,
//   required String hint,
//   required TextEditingController controller,
// }) {
//   final today = DateTime.now();
//   final startDate = today.subtract(const Duration(days: 180));
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text(
//         label,
//         style: const TextStyle(
//           fontFamily: 'Inter',
//           fontWeight: FontWeight.w500,
//           fontSize: 14,
//           color: AppTheme.merchantNavy,
//         ),
//       ),
//       const SizedBox(height: 8),
//       TextFormField(
//         controller: controller,
//         readOnly: true,
//         style: const TextStyle(
//           fontFamily: 'Inter',
//           fontSize: 14,
//           color: AppTheme.merchantNavy,
//         ),
//         onTap: () async {
//           DateTime? initialDate;

//           if (controller.text.isNotEmpty) {
//             try {
//               initialDate = DateFormat('dd/MM/yyyy').parse(controller.text);
//             } catch (_) {}
//           }
//           final pickedDate = await DatePickerService.showDatePickerGlobal(
//             context: context,
//             minDate: startDate,
//             maxDate: initialDate,
//             initialSelectedDate: initialDate,
//           );
//           if (pickedDate != null) {
//             final formatted = DateFormat('dd/MM/yyyy').format(pickedDate);
//             controller.text = formatted;
//           }
//         },
//         decoration: InputDecoration(
//           hintText: hint,
//           hintStyle: const TextStyle(color: AppTheme.merchantIconGrey),
//           suffixIcon: const Icon(
//             Icons.calendar_today_rounded,
//             size: 18,
//             color: AppTheme.merchantIconGrey,
//           ),
//           filled: true,
//           fillColor: Colors.white.withOpacity(0.6),
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: 14,
//           ),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: const BorderSide(color: Colors.white, width: 1.5),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: const BorderSide(color: Colors.white, width: 1.5),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: const BorderSide(
//               color: AppTheme.merchantAccent,
//               width: 2,
//             ),
//           ),
//         ),
//       ),
//     ],
//   );
// }

class ReportsTable extends StatefulWidget {
  final List<ReportEntity> reports;
  const ReportsTable({required this.reports});

  @override
  State<ReportsTable> createState() => ReportsTableState();
}

class ReportsTableState extends State<ReportsTable> {
  int? _sortColumnIndex;
  bool _isAscending = true;
  late List<ReportEntity> _sortedReports;

  static const List<String> _columnHeaders = [
    'schedule name',
    'Type',
    'Generated On',
    'Size',
    'Status',
    'Download',
  ];
  // Sticky Header Approach Flags & Variables
  final bool useStickyHeader = true;
  bool _isCalculatingWidths = false;
  List<double> _columnWidths = [];

  @override
  void initState() {
    super.initState();
    _sortedReports = List.from(widget.reports);
    _calculateColumnWidths();
  }

  @override
  void didUpdateWidget(covariant ReportsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reports != oldWidget.reports) {
      _sortedReports = List.from(widget.reports);
      if (_sortColumnIndex != null) {
        _sort(_sortColumnIndex!, _isAscending);
      } else {
        _calculateColumnWidths();
      }
    }
  }

  Future<void> _calculateColumnWidths() async {
    if (!mounted) return;
    setState(() => _isCalculatingWidths = true);
    await Future.microtask(() {});
    if (!mounted) return;

    final TextStyle headerStyle =
        Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold) ??
        const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Color(0xFF99A1AF),
        );
    final TextStyle dataStyle =
        Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500) ??
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.merchantTextSecondaryDarkGrey,
        );

    List<List<String>> columnValues = List.generate(
      _columnHeaders.length,
      (_) => [],
    );
    for (final r in _sortedReports) {
      columnValues[0].add(r.reportName);
      columnValues[1].add(r.reportType);
      columnValues[2].add(r.generatedOn);
      columnValues[3].add(r.fileSize);
      columnValues[4].add(r.reportStatus);
      columnValues[5].add('');
    }

    List<double> calculatedWidths = [];
    for (int i = 0; i < _columnHeaders.length; i++) {
      final headerPainter = TextPainter(
        text: TextSpan(text: _columnHeaders[i], style: headerStyle),
        maxLines: 1,
        textDirection: ui.TextDirection.ltr,
      )..layout();
      double maxWidth = headerPainter.width + 32.0;

      for (final cellText in columnValues[i]) {
        final painter = TextPainter(
          text: TextSpan(text: cellText, style: dataStyle),
          maxLines: 1,
          textDirection: ui.TextDirection.ltr,
        )..layout();
        final w = painter.width + 28.0;
        if (w > maxWidth) maxWidth = w;
      }
      calculatedWidths.add(maxWidth);
    }
    calculatedWidths[2] = calculatedWidths[2].clamp(
      140.0,
      180.0,
    ); // TRANSACTION STATUS
    calculatedWidths[3] = calculatedWidths[3].clamp(
      140.0,
      180.0,
    ); // REFUND STATUS
    calculatedWidths[4] = calculatedWidths[4].clamp(
      140.0,
      180.0,
    ); // RE-INITIATE REFUND
    calculatedWidths[5] = 60.0; // Action vertical dots

    if (!mounted) return;
    setState(() {
      _columnWidths = calculatedWidths;
      _isCalculatingWidths = false;
    });
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
      _sortedReports.sort((a, b) {
        int cmp = 0;
        switch (columnIndex) {
          case 0:
            cmp = a.reportName.compareTo(b.reportName);
            break;
          case 1:
            cmp = a.reportType.compareTo(b.reportType);
            break;
          case 2:
            cmp = a.generatedOn.compareTo(b.generatedOn);
            break;
          case 3:
            cmp = a.fileSize.compareTo(b.fileSize);
            break;
          case 4:
            cmp = a.reportStatus.compareTo(b.reportStatus);
            break;
          case 5:
            cmp = a.reportStatus.compareTo(b.reportStatus);
            break;
        }
        return ascending ? cmp : -cmp;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _sortedReports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildMobileCard(_sortedReports[index], context),
          );
        }

        return _buildDesktopTable(constraints.maxWidth);
      },
    );
  }

  Widget _buildDesktopTable(double maxWidth) {
    if (_isCalculatingWidths || _columnWidths.isEmpty) {
      return SizedBox(height: 200, child: Center(child: GifProgressBar()));
    }

    double totalWidth = _columnWidths.fold(0, (sum, w) => sum + w);
    List<double> finalWidths = List.from(_columnWidths);

    if (totalWidth < maxWidth && finalWidths.isNotEmpty) {
      double extraSpace = maxWidth - totalWidth;
      // Use floor to prevent fractional pixel rounding overlaps
      double extraPerColumn = ((extraSpace - 2.0) / finalWidths.length)
          .floorToDouble();
      if (extraPerColumn > 0) {
        for (int i = 0; i < finalWidths.length; i++) {
          finalWidths[i] += extraPerColumn;
        }
      }
    }

    final tableWidth = finalWidths.fold(0.0, (sum, w) => sum + w);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
        child: SizedBox(
          width: tableWidth,
          child: Column(
            children: [
              _buildTableHeader(finalWidths),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _sortedReports.length,
                  itemBuilder: (context, index) {
                    return buildCustomDataRow(
                      _sortedReports[index],
                      index,
                      finalWidths,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(List<double> widths) {
    return Container(
      height: 57,
      decoration: const BoxDecoration(
        color: AppTheme.merchantTableHeading,
        border: Border(
          bottom: BorderSide(color: AppTheme.merchantBorder, width: 1.5),
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: widths.asMap().entries.map((entry) {
          final index = entry.key;
          final width = entry.value;
          final header = _columnHeaders[index];

          return SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Align(
                alignment: index == 5 ? Alignment.center : Alignment.centerLeft,
                child: Text(
                  header.toUpperCase(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.merchantTableHeaderFont,
                    fontSize: 10.85,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildCustomDataRow(
    ReportEntity report,
    int index,
    List<double> widths,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.merchantCardBg,
        border: Border(
          bottom: BorderSide(color: Color(0x14000000), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: widths[0],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              child: Text(report.reportName?.toString() ?? ''),
            ),
          ),
          SizedBox(
            width: widths[1],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildTypeChip(report.reportType?.toString() ?? ''),
              ),
            ),
          ),
          SizedBox(
            width: widths[2],
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 10.0,
              ),
              child: Text(report.generatedOn.toString() ?? ''),
            ),
          ),
          SizedBox(
            width: widths[3],
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 10.0,
              ),
              child: Text(report.fileSize.toString() ?? ''),
            ),
          ),
          SizedBox(
            width: widths[4],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusChip(report.reportStatus?.toString() ?? ''),
              ),
            ),
          ),
          SizedBox(
            width: widths[5],
            child: Center(
              child: BlocBuilder<ReportHistoryBloc, ReportHistoryState>(
                buildWhen: (previous, current) =>
                    current is DownloadReportLoading ||
                    current is DownloadReportLoaded,
                builder: (context, state) {
                  return IconButton(
                    icon: const Icon(Icons.download_rounded, size: 18),
                    onPressed: () {
                      context.read<ReportHistoryBloc>().add(
                        DownloadReportEvent(
                          reportId: '${report.reportId}',
                          scheduleName: '${report.reportName}',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    String text, {
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final value = status.toLowerCase();

    Color bgColor;
    Color textColor;

    if (value == 'ready' ||
        value == 'success' ||
        value == 'completed' ||
        value == 'active') {
      bgColor = const Color(0xFFD9FBE7);
      textColor = const Color(0xFF1C9B5F);
    } else if (value == 'pending' || value == 'processing') {
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
    } else if (value == 'failed' || value == 'error') {
      bgColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
    } else {
      bgColor = const Color(0xFFF3F4F6);
      textColor = const Color(0xFF6B7280);
    }

    return _buildChip(status, bgColor: bgColor, textColor: textColor);
  }

  Widget _buildTypeChip(String type) {
    return _buildChip(
      type,
      bgColor: const Color(0xFFDCE9FF),
      textColor: const Color(0xFF2B50D9),
    );
  }

  Widget _buildMobileCard(ReportEntity report, BuildContext context) {
    return Container();
  }
}
