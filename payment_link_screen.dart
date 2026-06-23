import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hdfc_merchant_app/core/util/nullable_extensions.dart';
import 'package:hdfc_merchant_app/features/payment_link/bloc/payment_link_filter_cubit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hdfc_merchant_app/core/theme/app_theme.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/utils/date_range.dart';
import 'package:hdfc_merchant_app/features/payment_link/data/payment_link_repository_copy.dart';
import 'package:hdfc_merchant_app/shared/calender/alendar_cubit.dart';
import 'package:hdfc_merchant_app/shared/calender/widgets/global_calendar_toggle.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/util/gif_progressbar.dart';
import '../../../shared/widgets/pagination_control.dart';
import '../bloc/payment_link_history_bloc.dart';
import '../bloc/payment_link_history_event.dart';
import '../bloc/payment_link_history_state.dart';
import '../data/payment_link_model.dart';
import 'create_payment_link_dialog.dart';

class PaymentLinksScreen extends StatelessWidget {
  const PaymentLinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final calendarState = context.read<CalendarCubit>().state;
            final bloc = PaymentLinkHistoryBloc(
              repository: PaymentLinkRepository(),
            );
            final dateRange = DateRangeHelper.getDateRange("Today");
            final fromDate = dateRange.fromDate;
            final toDate = dateRange.toDate;
            bloc.add(
              PaymentLinkHistoryDateRangeChanged(
                fromDate: fromDate,
                toDate: toDate,
                timeFrame: calendarState.timeFrame,
              ),
            );

            return bloc;
          },
        ),
        BlocProvider(create: (_) => PaymentLinkFilterCubit()),
      ],
      child: const PaymentLinksView(),
    );
  }
}

class PaymentLinksView extends StatefulWidget {
  const PaymentLinksView({super.key});

  @override
  State<PaymentLinksView> createState() => _PaymentLinksViewState();
}

class _PaymentLinksViewState extends State<PaymentLinksView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final PaymentLinkSearchField _selectedField = PaymentLinkSearchField.orderId;
  String _selectedStatus = 'All Status';
  String _selectedDaysFilter = 'Today';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: const BoxDecoration(gradient: AppTheme.merchantBgGradient),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: _buildHeader(context, isMobile),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                child: _buildSubtitle(isMobile),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
                child: _buildMetricsGrid(context, isMobile),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
                child: _buildSearchAndFilterSection(context, isMobile),
              ),
              if (isMobile)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
                  child: SizedBox(height: 400, child: _buildContent(context)),
                )
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
                    child: _buildContent(context),
                  ),
                ),
            ],
          );

          return isMobile ? SingleChildScrollView(child: content) : content;
        },
      ),
    );
  }

  Widget _buildSubtitle(bool isMobile) {
    return const Text(
      'Create and manage payment links for your customers',
      style: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.43,
        color: Color(0xFF6A7282),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, bool isMobile) {
    final state = context.watch<PaymentLinkHistoryBloc>().state;
    final summary = state is PaymentLinkHistoryPaginationLoaded
        ? state.summary
        : null;

    final cards = [
      _buildMetricCard(
        context,
        'Total Links',
        (summary?.totalLinks == null || summary?.totalLinks == 0)
            ? '—'
            : summary?.totalLinks.toString(),
      ),
      _buildMetricCard(
        context,
        'Active Links',
        (summary?.activeLinks == null || summary?.activeLinks == 0)
            ? '—'
            : summary?.activeLinks.toString(),
      ),

      _buildMetricCard(
        context,
        'Total Clicks',
        (summary?.clickCount == null || summary?.clickCount == 0)
            ? '—'
            : summary?.activeLinks.toString(),
      ),
      _buildMetricCard(
        context,
        'Click Rate',
        (summary?.clickRate == null || summary?.clickRate == '0.00%')
            ? '—'
            : summary?.clickRate.toString(),
      ),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: cards,
      );
    }

    return Row(
      children:
          cards
              .map(
                (card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: card,
                  ),
                ),
              )
              .toList()
            ..removeLast()
            ..add(Expanded(child: cards.last)),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String? value) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.merchantCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.merchantBorder, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.42,
              color: Color(0xFF6A7282), // Slate grey
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 30,
              height: 1.2,
              color: Color(0xCC000000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection(BuildContext context, bool isMobile) {
    return BlocBuilder<PaymentLinkHistoryBloc, PaymentLinkHistoryState>(
      builder: (context, state) {
        final loaded = state is PaymentLinkHistoryPaginationLoaded
            ? state
            : null;
        final List<String> statusItems = [
          'All Status',
          'Completed',
          'Failed',
          'Pending',
        ];

        final List<String> dateOptions = [
          'Today',
          'Yesterday',
          'Last 7 Days',
          'Last 15 Days',
          'Last 30 Days',
          'Custom',
        ];

        final selectedDateRangeLabel = loaded?.selectedDateRange ?? 'Today';

        final bool isCustomSelected = selectedDateRangeLabel.startsWith(
          'Custom',
        );

        final List<String> dropdownItems = isCustomSelected
            ? [
                'Today',
                'Yesterday',
                'Last 7 Days',
                'Last 15 Days',
                'Last 30 Days',
                selectedDateRangeLabel, // Custom (09 Jun - 18 Jun)
              ]
            : [
                'Today',
                'Yesterday',
                'Last 7 Days',
                'Last 15 Days',
                'Last 30 Days',
                'Custom',
              ];

        final dropdownValue = dropdownItems.contains(selectedDateRangeLabel)
            ? selectedDateRangeLabel
            : dropdownItems.first;

        final searchField = Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.merchantCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.merchantBorder, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.search, //icon from figma replacement is pending @TODO HK
                size: 20,
                color: Color(0xFF6A7282),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (text) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 400), () {
                        setState(() {});
                      });
                    },
                    onSubmitted: (text) {
                      context.read<PaymentLinkHistoryBloc>().add(
                        PaymentLinkHistorySearchChanged(
                          text.trim(),
                          _selectedField,
                        ),
                      );
                    },
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      filled: false,
                      fillColor: Colors.transparent,
                      hintText: 'Search Order ID, Transaction ID',
                      hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFA3AED0),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),

              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    context.read<PaymentLinkHistoryBloc>().add(
                      PaymentLinkHistorySearchChanged('', _selectedField),
                    );
                    setState(() {});
                  },
                  child: const Icon(
                    Icons.clear,
                    size: 16,
                    color: Color(0x66000000),
                  ),
                ),
            ],
          ),
        );

        final statusDropdown = Container(
          width: isMobile ? double.infinity : 160,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.merchantCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.merchantBorder, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0x66000000),
              ),
              isExpanded: true,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: AppTheme.merchantTextSecondaryDarkGrey,
                height: 1.42,
                letterSpacing: -0.15,
              ),
              dropdownColor: Theme.of(context).cardColor,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedStatus = value;
                });
                context.read<PaymentLinkHistoryBloc>().add(
                  PaymentLinkHistoryStatusChanged(value),
                );
              },
              items: statusItems.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
            ),
          ),
        );

        final daysDropdown = Container(
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
              value: dropdownValue,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0x66000000),
              ),
              isExpanded: true,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: AppTheme.merchantTextSecondaryDarkGrey,
                height: 1.42,
                letterSpacing: -0.15,
              ),
              dropdownColor: Theme.of(context).cardColor,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedDaysFilter = value;
                });

                final dateRange = DateRangeHelper.getDateRange(value);
                final fromDate = dateRange.fromDate;
                final toDate = dateRange.toDate;
                context.read<PaymentLinkHistoryBloc>().add(
                  PaymentLinkHistoryDateRangeChanged(
                    fromDate: fromDate,
                    toDate: toDate,
                    timeFrame: value,
                  ),
                );
              },
              items: dropdownItems.map((item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
            ),
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: statusDropdown),
                  const SizedBox(width: 16),
                  Expanded(child: daysDropdown),
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
            daysDropdown,
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    const title = 'Payment Links';
    final createButton = ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const CreatePaymentLinkDialog(),
        ).then((_) {
          if (context.mounted) {
            context.read<PaymentLinkHistoryBloc>().add(
              const PaymentLinkHistoryFetched(isRefresh: true),
            );
          }
        });
      },
      icon: const Icon(Icons.add, size: 20),
      label: const Text(
        'Create Payment Link',
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.white,
          height: 1.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.merchantAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,

              color: const Color(0xFF0E2391), //0E2391
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: GlobalCalendarToggle(
                  top: 0,
                  right: 0,
                  showTimeFrames: true,
                ),
              ),
              const SizedBox(width: 8),
              _buildRefreshButton(context),
            ],
          ),
          const SizedBox(height: 12),
          createButton,
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 34,
              height: 1.23,
              color: const Color(0xFF0E2391), //
              letterSpacing: -0.5,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // const GlobalCalendarToggle(
              //   top: 0,
              //   right: 0,
              //   showTimeFrames: true,
              // ),
              // const SizedBox(width: 12),
              // _buildRefreshButton(context),
              const SizedBox(width: 12),
              createButton,
            ],
          ),
        ],
      );
    }
  }

  Widget _buildRefreshButton(BuildContext context) {
    return BlocSelector<PaymentLinkHistoryBloc, PaymentLinkHistoryState, bool>(
      selector: (state) => state is PaymentLinkHistoryLoading,
      builder: (context, isLoading) {
        return IconButton(
          icon: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                )
              : const Icon(Icons.refresh),
          onPressed: isLoading
              ? null
              : () => context.read<PaymentLinkHistoryBloc>().add(
                  const PaymentLinkHistoryFetched(isRefresh: true),
                ),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(12),
          ),
          tooltip: isLoading ? 'Refreshing...' : 'Refresh',
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 3),
      child: BlocConsumer<PaymentLinkHistoryBloc, PaymentLinkHistoryState>(
        listener: (context, state) {
          if (state is PaymentLinkHistoryFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is PaymentLinkHistoryLoading) {
            return GifProgressBar();
          } else if (state is PaymentLinkHistoryPaginationLoaded) {
            return _PaymentLinksTablePaginated(
              paymentLinks: state.paymentLinks,
              totalRecords: state.totalRecords,
              currentPage: state.currentPage,
              totalPages: state.totalPages,
              rowsPerPage: state.rowsPerPage,
            );
          } else if (state is PaymentLinkHistoryFailure) {
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
          return const Center(child: Text('Payment Links'));
        },
      ),
    );
  }
}

class PaymentLinksTable extends StatefulWidget {
  final List<PaymentLinkEntity> paymentLinks;
  const PaymentLinksTable({super.key, required this.paymentLinks});

  @override
  State<PaymentLinksTable> createState() => _PaymentLinksTableState();
}

class _PaymentLinksTableState extends State<PaymentLinksTable> {
  int? _sortColumnIndex;
  bool _isAscending = true;
  late List<PaymentLinkEntity> _sortedLinks;
  bool _isCalculatingWidths = false;
  List<double> _columnWidths = [];

  static const List<String> _columnHeaders = [
    'Order ID',
    'Transaction ID',
    'Amount',
    'Order Status',
    'Link Status',
    'Created By',
    'Timestamp',
    'Expiry',
    'Link URL',
  ];

  @override
  void initState() {
    super.initState();
    _sortedLinks = List.from(widget.paymentLinks);
    _calculateColumnWidths();
  }

  @override
  void didUpdateWidget(covariant PaymentLinksTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paymentLinks != oldWidget.paymentLinks) {
      _sortedLinks = List.from(widget.paymentLinks);
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
    for (final t in _sortedLinks) {
      columnValues[0].add(t.orderId.orEmpty);
      columnValues[1].add(t.txnId.orZero.toString());
      columnValues[2].add(t.formattedAmount);
      columnValues[3].add(t.orderStatus.orEmpty);
      columnValues[4].add(t.linkStatus.orEmpty);
      columnValues[5].add(t.createdByUserId.orEmpty.toString());
      columnValues[6].add(t.createdAt.toString());
      columnValues[7].add(t.formattedExpiry);
      columnValues[8].add(t.paymentUrl.orEmpty);
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
    calculatedWidths[3] = calculatedWidths[3].clamp(
      110.0,
      160.0,
    ); // Order Status Chip
    calculatedWidths[4] = calculatedWidths[4].clamp(
      110.0,
      160.0,
    ); // Link Status Chip
    calculatedWidths[8] = calculatedWidths[8].clamp(
      180.0,
      300.0,
    ); // Link URL column width

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
      _sortedLinks.sort((a, b) {
        int cmp = 0;
        switch (columnIndex) {
          case 0:
            cmp = a.orderId.orEmpty.compareTo(b.orderId.orEmpty);
            break;
          case 1:
            cmp = a.txnId.orZero.compareTo(b.txnId.orZero);
            break;
          case 2:
            cmp = a.paymentAmount.orZero.compareTo(b.paymentAmount.orZero);
            break;
          case 3:
            cmp = a.orderStatus.orEmpty.compareTo(b.orderStatus.orEmpty);
            break;
          case 4:
            cmp = a.linkStatus.orEmpty.compareTo(b.linkStatus.orEmpty);
            break;
          case 5:
            cmp = a.createdByUserId.orEmpty.compareTo(
              b.createdByUserId.orEmpty,
            );
            break;
          case 6:
            cmp = a.createdAt!.compareTo(b.createdAt!);
            break;
          case 7:
            cmp = (a.expiryTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
                  b.expiryTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0),
                );
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
            itemCount: _sortedLinks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildMobileCard(context, _sortedLinks[index]),
          );
        } else {
          return _buildDesktopTable(constraints.maxWidth);
        }
      },
    );
  }

  Widget _buildTableHeader(List<double> widths) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.merchantTableHeading,
        border: Border(
          bottom: BorderSide(color: AppTheme.merchantBorder, width: 1.5),
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      height: 57,
      child: Row(
        children: widths.asMap().entries.map((entry) {
          final index = entry.key;
          final width = entry.value;
          final header = _columnHeaders[index];

          return SizedBox(
            width: width,
            child: InkWell(
              onTap: () => _sort(
                index,
                _sortColumnIndex == index ? !_isAscending : true,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        header.toUpperCase(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.merchantTableHeaderFont,
                          fontSize: 10.85,
                          height: 1.33,
                          letterSpacing: 0.543,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_sortColumnIndex == index)
                      Icon(
                        _isAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                        color: AppTheme.merchantTableHeaderFont,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDesktopTable(double maxWidth) {
    if (_isCalculatingWidths || _columnWidths.isEmpty) {
      return SizedBox(height: 200, child: Center(child: GifProgressBar()));
    }

    double totalWidth = _columnWidths.fold(0.0, (sum, w) => sum + w);
    List<double> finalWidths = List.from(_columnWidths);

    if (totalWidth < maxWidth && finalWidths.isNotEmpty) {
      double extraSpace = maxWidth - totalWidth;
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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
          borderRadius: BorderRadius.vertical(
            bottom: Radius.zero,
            top: Radius.circular(16),
          ),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
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
                  itemCount: _sortedLinks.length,
                  itemBuilder: (context, index) => _buildCustomDataRow(
                    _sortedLinks[index],
                    index,
                    finalWidths,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDataRow(
    PaymentLinkEntity link,
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
        children: List.generate(widths.length, (colIndex) {
          Widget child;
          switch (colIndex) {
            case 0: // ORDER ID
              child = Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 14.0,
                ),
                child: Text(
                  link.orderId.orEmpty,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1957B1),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              );
              break;
            case 1: // Txn ID
              child = Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 14.0,
                ),
                child: Text(
                  link.txnId != null ? link.txnId.toString() : '__',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    color: Color(0xCC000000),
                    fontSize: 14,
                    height: 1.42,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              );
              break;
            case 2: // AMOUNT
              child = Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 14.0,
                ),
                child: Text(
                  link.formattedAmount,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B2559),
                    fontSize: 14,
                    height: 1.42,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              );
              break;
            case 3: // ORDER STATUS CHIP
              child = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _CustomStatusChip.order(link.orderStatus.orEmpty),
                ),
              );
              break;
            case 4: // LINK STATUS CHIP
              child = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _CustomStatusChip.link(link.linkStatus.orEmpty),
                ),
              );
              break;
            case 5: // CREATED BY
              child = Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 14.0,
                ),
                child: Text(
                  link.createdByUserId.orEmpty.toString(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    color: Color(0xCC000000),
                    fontSize: 14,
                    height: 1.42,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              );
              break;
            case 6: // TIMESTAMP
              child = Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 14.0,
                ),
                child: Text(
                  link.formattedCreatedAt,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    color: Color(0xCC000000),
                    fontSize: 14,
                    height: 1.42,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              );
              break;
            case 7: // EXPIRY
              child = Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 14.0,
                ),
                child: Text(
                  link.formattedExpiry,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    color: Color(0xCC000000),
                    fontSize: 14,
                    height: 1.42,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              );
              break;
            case 8: // LINK URL (Link + Copy)
              final url = link.paymentUrl.orEmpty;
              if (url == null || url.isEmpty) {
                child = const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 14.0,
                  ),
                  child: Text(
                    '__',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      color: Color(0xCC000000),
                      fontSize: 14,
                      height: 1.42,
                    ),
                  ),
                );
              } else {
                child = Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse(url);
                            try {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (e) {
                              // debugPrint('Could not launch $url: $e');
                            }
                          },
                          child: Text(
                            url,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1957B1),
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF1957B1),
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: AppTheme.merchantAccent,
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment link copied to clipboard'),
                            ),
                          );
                        },
                        tooltip: 'Copy Payment Link',
                      ),
                    ],
                  ),
                );
              }
              break;
            default:
              child = const SizedBox.shrink();
          }
          return SizedBox(width: widths[colIndex], child: child);
        }),
      ),
    );
  }

  Widget _buildMobileCard(BuildContext context, PaymentLinkEntity link) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  link.orderId.orEmpty,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.merchantAccent,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                link.createdAt.toString(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                  Text(
                    link.formattedAmount,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _CustomStatusChip.order(link.orderStatus.orEmpty),
                  const SizedBox(width: 6),
                  _CustomStatusChip.link(link.linkStatus.orEmpty),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Txn ID: ${link.txnId.orZero} • By: ${link.createdByUserId.orEmpty}',
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.merchantIconGrey,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: AppTheme.merchantAccent,
                ),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: link.paymentUrl.orEmpty),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment link copied to clipboard'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Exp: ${link.formattedExpiry}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _PaymentLinksTablePaginated extends StatelessWidget {
  final List<PaymentLinkEntity> paymentLinks;
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final int rowsPerPage;

  const _PaymentLinksTablePaginated({
    required this.paymentLinks,
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
    required this.rowsPerPage,
  });

  @override
  Widget build(BuildContext context) {
    if (totalRecords <= 0) {
      return Center(
        child: Text(
          "No Records Found",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      );
    }

    return Column(
      children: [
        Expanded(child: PaymentLinksTable(paymentLinks: paymentLinks)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: PaginationControl(
            currentPage: currentPage,
            totalPages: totalPages,
            totalRecords: totalRecords,
            rowsPerPage: rowsPerPage,
            onPageChanged: (page) {
              context.read<PaymentLinkHistoryBloc>().add(
                PaymentLinkHistoryPageChanged(page),
              );
            },
            onRowsPerPageChanged: (rows) {
              context.read<PaymentLinkHistoryBloc>().add(
                PaymentLinkHistoryRowsPerPageChanged(rows),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CustomStatusChip extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;

  const _CustomStatusChip({
    required this.label,
    required this.textColor,
    required this.bgColor,
  });

  factory _CustomStatusChip.order(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const _CustomStatusChip(
          label: 'Completed',
          textColor: Color(0xFF059669), // Green
          bgColor: Color(0xFFD1FAE5),
        );
      case 'failed':
        return const _CustomStatusChip(
          label: 'Failed',
          textColor: Color(0xFFDC2626), // Red
          bgColor: Color(0xFFFEE2E2),
        );
      case 'pending':
        return const _CustomStatusChip(
          label: 'Pending',
          textColor: Color(0xFFD97706), // Yellow/Orange
          bgColor: Color(0xFFFEF3C7),
        );

      default:
        return _CustomStatusChip(
          label: status,
          textColor: const Color(0xFF6B7280),
          bgColor: const Color(0xFFF3F4F6),
        );
    }
  }

  factory _CustomStatusChip.link(String status) {
    switch (status.toLowerCase()) {
      case 'fulfilled':
        return const _CustomStatusChip(
          label: 'Fulfilled',
          textColor: Color(0xFF059669), // Green
          bgColor: Color(0xFFD1FAE5),
        );
      case 'expired':
        return const _CustomStatusChip(
          label: 'Expired',
          textColor: Color(0xFF6B7280), // Grey
          bgColor: Color(0xFFF3F4F6),
        );
      case 'active':
        return const _CustomStatusChip(
          label: 'Active',
          textColor: Color(0xFF1E40AF), // Blue
          bgColor: Color(0xFFDBEAFE),
        );
      case 'failed':
        return const _CustomStatusChip(
          label: 'Failed',
          // Blue
          textColor: Color(0xFFDC2626), // Red
          bgColor: Color(0xFFFEE2E2),
        );
      default:
        return _CustomStatusChip(
          label: status,
          textColor: const Color(0xFF6B7280),
          bgColor: const Color(0xFFF3F4F6),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 12,
        ),
      ),
    );
  }
}
