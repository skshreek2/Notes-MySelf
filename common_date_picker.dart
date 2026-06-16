import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hdfc_merchant_app/core/theme/app_theme.dart';
import 'package:hdfc_merchant_app/core/util/common.dart';
import 'package:hdfc_merchant_app/core/util/gif_progressbar.dart';
import 'package:hdfc_merchant_app/features/analytics/data/analytics_response.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/utils/date_range.dart';
import 'package:hdfc_merchant_app/features/transactions/analytics/widgets/app_dropdown.dart';
import 'package:hdfc_merchant_app/features/transactions/analytics/widgets/transaction_volume_chart.dart';
import 'package:hdfc_merchant_app/shared/widgets/pagination_control.dart';
import '../bloc/analytics_bloc.dart';
import '../bloc/analytics_event.dart';
import '../bloc/analytics_state.dart';
import '../data/analytics_model.dart';
import '../data/analytics_repository.dart';
import '../../transactions/analytics/widgets/app_dropdown.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Entry point
// ─────────────────────────────────────────────────────────────────────────────

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print("Analytics Screen");

    final dateRange = DateRangeHelper.getDateRange('Today');
    final fromDate = dateRange.fromDate;
    final toDate = dateRange.toDate;
    print("STARTDATE $fromDate ENDDATE $toDate");
    return BlocProvider(
      create: (_) =>
          AnalyticsBloc(repository: AnalyticsRepository())
            ..add(AnalyticsFetched(fromDate: fromDate, toDate: toDate)),
      child: const _AnalyticsView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Root view (gradient container + layout builder)
// ─────────────────────────────────────────────────────────────────────────────

class _AnalyticsView extends StatefulWidget {
  const _AnalyticsView();

  @override
  State<_AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<_AnalyticsView> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: const BoxDecoration(gradient: AppTheme.merchantBgGradient),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;
          // Table gets 60% of available height if bounded, fallback to 480px.
          final tableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight * 0.60
              : 480.0;

          if (isMobile) {
            // Mobile: everything in one scrollable column
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isMobile),
                  const SizedBox(height: 4),
                  _buildSubtitle(),
                  const SizedBox(height: 24),
                  _buildSummarySection(context, isMobile),
                  const SizedBox(height: 28),
                  const Text(
                    'Transaction Details',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: AppTheme.merchantNavy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSearchAndFilter(context, isMobile),
                  const SizedBox(height: 16),
                  SizedBox(height: 420, child: _buildTableSection(context)),
                ],
              ),
            );
          }

          // always fully visible and its rows scroll internally.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Pinned ────────────────────────────────────────────────────
              _buildHeader(context, isMobile),
              const SizedBox(height: 4),
              _buildSubtitle(),
              const SizedBox(height: 24),
              // ── Scrollable (KPI cards → chart → details → search → table) ─
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KPI metric cards + bar chart
                      _buildSummarySection(context, isMobile),
                      const SizedBox(height: 28),
                      // Section heading
                      const Text(
                        'Transaction Details',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: AppTheme.merchantNavy,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search + status filter
                      _buildSearchAndFilter(context, isMobile),
                      const SizedBox(height: 16),
                      // Table + pagination — fixed height so rows scroll inside
                      SizedBox(
                        height: tableHeight,
                        child: _buildTableSection(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        final loaded = state is AnalyticsLoaded ? state : null;
        // final selectedMethod = loaded?.selectedMethod ?? 'All Payment Methods';
        // final selectedRange = loaded?.selectedDateRange ?? 'Last 30 Days';
        final isExporting = loaded?.isExporting ?? false;

        final List<String> items = [
          'All Payment Methods',
          'UPI',
          'Net Banking',
          'Debit Card',
          'Credit Card',
        ];

        final List<String> daysRange = [
          'Today',
          'Yesterday',
          'Last 7 Days',
          'Last 15 Days',
          'Last 30 Days',
          'Custom',
        ];

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Transaction Analytics',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: Color(0xFF0E2391),
                ),
              ),
              const SizedBox(height: 12),
              // methodDropdown,
              AppDropdown<String>(
                width: 200,
                items: items,
                onChanged: (value) {
                  if (value != null) {
                    context.read<AnalyticsBloc>().add(
                      AnalyticsPaymentMethodChanged(value),
                    );
                  }
                },
                value: items.contains(loaded?.selectedMethod)
                    ? loaded?.selectedMethod
                    : items.first,
              ),
              const SizedBox(height: 8),
              // rangeDropdown,
              AppDropdown(
                items: daysRange,
                width: double.infinity,
                onChanged: (value) {
                  if (value != null) {
                    context.read<AnalyticsBloc>().add(
                      AnalyticsDateRangeChanged(value),
                    );
                  }
                },
                value: daysRange.contains(loaded?.selectedDateRange)
                    ? loaded?.selectedDateRange
                    : daysRange.first,
              ),
              const SizedBox(height: 12),
              // exportButton,
            ],
          );
        }

        return Row(
          children: [
            const Text(
              'Transaction Analytics',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 34,
                height: 1.23,
                color: Color(0xFF0E2391),
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            // methodDropdown,
            AppDropdown(
              width: 200,
              items: items,
              onChanged: (value) {
                print("Value Changes $value");
                if (value != null) {
                  context.read<AnalyticsBloc>().add(
                    AnalyticsPaymentMethodChanged(value),
                  );
                }
              },
              value: items.contains(loaded?.selectedMethod)
                  ? loaded?.selectedMethod
                  : items.first,
            ),
            const SizedBox(width: 12),
            // rangeDropdown,
            AppDropdown(
              items: daysRange,
              width: 160,
              onChanged: (value) {
                if (value != null) {
                  context.read<AnalyticsBloc>().add(
                    AnalyticsDateRangeChanged(value),
                  );
                }
              },
              value: daysRange.contains(loaded?.selectedDateRange)
                  ? loaded?.selectedDateRange
                  : daysRange.first,
            ),
            const SizedBox(width: 12),
            // exportButton,
          ],
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Comprehensive insights into your transaction data',
      style: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.43,
        color: Color(0xFF6A7282),
      ),
    );
  }

  // ── Summary section: KPI cards + bar chart ──────────────────────────────────

  Widget _buildSummarySection(BuildContext context, bool isMobile) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is AnalyticsLoading || state is AnalyticsInitial) {
          return SizedBox(
            height: isMobile ? 420 : 220,
            child: GifProgressBar(),
          );
        }
        if (state is AnalyticsLoaded) {
          if (isMobile) {
            return Column(
              children: [
                _buildMetricCardsGrid(state.summary, isMobile),
                const SizedBox(height: 16),
                _buildChartCard(state.summary.transactionVolumeTrend, isMobile),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: 4 KPI cards in 2×2 grid
              SizedBox(
                width: 380,
                height: 308,
                child: _buildMetricCardsGrid(state.summary, isMobile),
              ),
              const SizedBox(width: 50),
              // Right: Bar chart
              Expanded(
                child: SizedBox(
                  height: 308,
                  child: _buildChartCard(
                    state.summary.transactionVolumeTrend,
                    isMobile,
                  ),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMetricCardsGrid(AnalyticsSummary summary, bool isMobile) {
    final cards = [
      _MetricCardData(
        title: 'Total Transactions',
        value:
            (summary.totalTransactions == null ||
                summary.totalTransactions == 0)
            ? '—'
            : _formatCount(summary.totalTransactions),
        // delta: summary.totalTransactionsDelta,
        deltaLabel: 'from last week',
      ),
      _MetricCardData(
        title: 'Failed Rate',
        value: (summary.failedRate == null || summary.failedRate == 0)
            ? '—'
            : '${summary.failedRate}%',
        // delta: sumanalyticsResponsemary.failedRateDelta,
        deltaLabel: 'from last week',
      ),
      _MetricCardData(
        title: 'Total Volume',
        value:
            (summary.totalVolumeLakhs == null || summary.totalVolumeLakhs == 0)
            ? '—'
            : '₹${formatRupeesIN(summary.totalVolumeLakhs)}',
        // delta: analyticsResponse.totalVolumeDelta,
        deltaLabel: 'from last week',
      ),
      _MetricCardData(
        title: 'Success Rate',
        value: (summary.successRate == null || summary.successRate == 0)
            ? '—'
            : '${summary.successRate}%',
        // delta: analyticsResponse.successRateDelta,
        deltaLabel: 'from last week',
      ),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
        children: cards.map(_buildMetricCard).toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 1.25,
      children: cards.map(_buildMetricCard).toList(),
    );
  }

  Widget _buildMetricCard(_MetricCardData data) {
    // final isPositiveDelta = data.delta >= 0;
    // For Failed Rate, a positive delta is actually bad (red)
    final isFailedRate = data.title == 'Failed Rate';
    // final isGreen = isFailedRate ? !isPositiveDelta : isPositiveDelta;

    // final deltaColor = isGreen
    //     ? const Color(0xFF12B76A)
    //     : const Color(0xFFE8192C);
    // final deltaPrefix = data.delta > 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.merchantCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.merchantBorder, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data.title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Color(0xFF6A7282),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 28,
              height: 1.2,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          // Row(
          //   children: [
          //     Icon(
          //       isGreen
          //           ? Icons.arrow_upward_rounded
          //           : Icons.arrow_downward_rounded,
          //       size: 12,
          //       color: deltaColor,
          //     ),
          //     const SizedBox(width: 2),
          //     Flexible(
          //       child: Text(
          //         "",
          //         // '$deltaPrefix${data.delta}% ${data.deltaLabel}',
          //         // style: TextStyle(
          //         //   fontFamily: 'Inter',
          //         //   fontWeight: FontWeight.w500,
          //         //   fontSize: 11,
          //         //   color: deltaColor,
          //         // ),
          //         // maxLines: 1,
          //         // overflow: TextOverflow.ellipsis,
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildChartCard(List<TransactionVolumeTrend> volumes, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.merchantCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.merchantBorder, width: 2),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction Volume & Rate',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.merchantNavy,
            ),
          ),
          const SizedBox(height: 20),
          isMobile
              ? SizedBox(
                  height: 150,
                  child: TransactionVolumeChart(volumes: volumes),
                )
              : Expanded(child: TransactionVolumeChart(volumes: volumes)),
        ],
      ),
    );
  }

  // ── Search + Status filter ──────────────────────────────────────────────────

  Widget _buildSearchAndFilter(BuildContext context, bool isMobile) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        final List<String> statusdropdowns = [
          'All Status',
          'Successful',
          'Pending',
          'Failed',
        ];

        final selectedStatus = state is AnalyticsLoaded
            ? state.selectedStatus
            : statusdropdowns.first;

        final searchField = Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.merchantCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.merchantBorder, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.search, size: 18, color: Color(0xFF6A7282)),
              const SizedBox(width: 10),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (text) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 400), () {
                        context.read<AnalyticsBloc>().add(
                          AnalyticsSearchChanged(text.trim()),
                        );
                      });
                      setState(() {});
                    },
                    textAlignVertical: TextAlignVertical.center,
                    decoration: const InputDecoration(
                      filled: false,
                      hintText: 'Search by transaction ID, customer name...',
                      hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFFA3AED0),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              if (_searchCtrl.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    context.read<AnalyticsBloc>().add(
                      const AnalyticsSearchChanged(''),
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

        // final statusDropdown = _buildStyledDropdown<String>(
        //   value: selectedStatus,
        //   items: const ['All Status', 'Successful', 'Pending', 'Failed'],
        //   onChanged: (v) {
        //     if (v != null) {
        //       context.read<AnalyticsBloc>().add(AnalyticsStatusChanged(v));
        //     }
        //   },
        //   width: isMobile ? double.infinity : 150,
        // );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 8),
              AppDropdown(
                items: statusdropdowns,
                onChanged: (v) {
                  if (v != null) {
                    context.read<AnalyticsBloc>().add(
                      AnalyticsStatusChanged(v),
                    );
                  }
                },
                value: selectedStatus,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 12),
            // statusDropdown,
            AppDropdown(
              items: statusdropdowns,
              onChanged: (v) {
                if (v != null) {
                  context.read<AnalyticsBloc>().add(AnalyticsStatusChanged(v));
                }
              },
              value: selectedStatus,
            ),
          ],
        );
      },
    );
  }

  // ── Table section ───────────────────────────────────────────────────────────

  Widget _buildTableSection(BuildContext context) {
    return BlocConsumer<AnalyticsBloc, AnalyticsState>(
      listener: (context, state) {
        if (state is AnalyticsFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is AnalyticsLoading || state is AnalyticsInitial) {
          return GifProgressBar();
        }
        if (state is AnalyticsLoaded) {
          return Column(
            children: [
              Expanded(
                child: _AnalyticsTable(transactions: state.transactions),
              ),
              // Pagination footer
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.4),
                    ),
                  ),
                ),
                child: PaginationControl(
                  currentPage: state.currentPage,
                  totalPages: state.totalPages,
                  totalRecords: state.totalRecords,
                  rowsPerPage: state.rowsPerPage,
                  onPageChanged: (p) => context.read<AnalyticsBloc>().add(
                    AnalyticsPageChanged(p),
                  ),
                  onRowsPerPageChanged: (r) => context
                      .read<AnalyticsBloc>()
                      .add(AnalyticsRowsPerPageChanged(r)),
                ),
              ),
            ],
          );
        }
        if (state is AnalyticsFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: AppTheme.merchantIconGrey,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.merchantIconGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // ElevatedButton(
                //   onPressed: () => context.read<AnalyticsBloc>().add(
                //     const AnalyticsFetched(
                //       isRefresh: true,
                //       fromDate: fromDate,
                //       toDate: toDate,
                //     ),
                //   ),
                //   child: const Text('Try Again'),
                // ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _formatCount(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    }
    return '$n';
  }
}

Widget _AnalyticsBarChart({required List<MonthlyVolume> volumes}) {
  return Padding(padding: EdgeInsetsGeometry.all(10));
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bar Chart Widget
// ─────────────────────────────────────────────────────────────────────────────
//
// class _AnalyticsBarChart extends StatefulWidget {
//   final List<MonthlyVolume> volumes;
//   const _AnalyticsBarChart({required this.volumes});
//
//   @override
//   State<_AnalyticsBarChart> createState() => _AnalyticsBarChartState();
// }
//
// class _AnalyticsBarChartState extends State<_AnalyticsBarChart> {
//   int? _touchedIndex;
//
//   @override
//   Widget build(BuildContext context) {
//     if (widget.volumes.isEmpty) return const SizedBox.shrink();
//
//     final maxCount = widget.volumes
//         .map((v) => v.count)
//         .reduce((a, b) => a > b ? a : b)
//         .toDouble();
//
//     return BarChart(
//       BarChartData(
//         maxY: maxCount * 1.2,
//         barTouchData: BarTouchData(
//           touchCallback: (event, response) {
//             if (!event.isInterestedForInteractions ||
//                 response == null ||
//                 response.spot == null) {
//               setState(() => _touchedIndex = null);
//               return;
//             }
//             setState(() => _touchedIndex = response.spot!.touchedBarGroupIndex);
//           },
//           touchTooltipData: BarTouchTooltipData(
//             getTooltipColor: (_) => AppTheme.merchantNavy,
//             getTooltipItem: (group, groupIndex, rod, rodIndex) {
//               final vol = widget.volumes[groupIndex];
//               return BarTooltipItem(
//                 '${vol.month}\n${vol.count} txns',
//                 const TextStyle(
//                   color: Colors.white,
//                   fontSize: 11,
//                   fontWeight: FontWeight.w600,
//                   fontFamily: 'Inter',
//                 ),
//               );
//             },
//           ),
//         ),
//         titlesData: FlTitlesData(
//           show: true,
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 24,
//               getTitlesWidget: (value, meta) {
//                 final idx = value.toInt();
//                 if (idx < 0 || idx >= widget.volumes.length) {
//                   return const SizedBox.shrink();
//                 }
//                 return Padding(
//                   padding: const EdgeInsets.only(top: 4),
//                   child: Text(
//                     widget.volumes[idx].month,
//                     style: const TextStyle(
//                       fontFamily: 'Inter',
//                       fontSize: 10,
//                       color: Color(0xFF6A7282),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           leftTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 36,
//               interval: maxCount / 2,
//               getTitlesWidget: (value, meta) {
//                 if (value == 0) return const SizedBox.shrink();
//                 final label = value >= 1000
//                     ? '${(value / 1000).toStringAsFixed(0)}K'
//                     : value.toStringAsFixed(0);
//                 return Text(
//                   label,
//                   style: const TextStyle(
//                     fontFamily: 'Inter',
//                     fontSize: 10,
//                     color: Color(0xFF6A7282),
//                   ),
//                 );
//               },
//             ),
//           ),
//           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         ),
//         gridData: FlGridData(
//           show: true,
//           drawVerticalLine: false,
//           horizontalInterval: maxCount / 2,
//           getDrawingHorizontalLine: (_) => const FlLine(
//             color: Color(0xFFE5E7EB),
//             strokeWidth: 1,
//             dashArray: [4, 4],
//           ),
//         ),
//         borderData: FlBorderData(show: false),
//         barGroups: widget.volumes.asMap().entries.map((entry) {
//           final idx = entry.key;
//           final vol = entry.value;
//           final isTouched = idx == _touchedIndex;
//           return BarChartGroupData(
//             x: idx,
//             barRods: [
//               BarChartRodData(
//                 toY: vol.count.toDouble(),
//                 width: 16,
//                 borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
//                 color: isTouched
//                     ? AppTheme.merchantAccent
//                     : AppTheme.merchantBarBg,
//                 backDrawRodData: BackgroundBarChartRodData(
//                   show: false,
//                 ),
//               ),
//             ],
//           );
//         }).toList(),
//       ),
//       duration: const Duration(milliseconds: 300),
//     );
//   }
// }

// ─────────────────────────────────────────────────────────────────────────────
//  Data Table Widget
// ─────────────────────────────────────────────────────────────────────────────

class _AnalyticsTable extends StatefulWidget {
  final List<AnalyticsTransaction> transactions;
  const _AnalyticsTable({required this.transactions});

  @override
  State<_AnalyticsTable> createState() => _AnalyticsTableState();
}

class _AnalyticsTableState extends State<_AnalyticsTable> {
  int? _sortColumnIndex;
  bool _isAscending = true;
  late List<AnalyticsTransaction> _sorted;
  List<double> _columnWidths = [];

  static const List<String> _headers = [
    'ORDER ID',
    'TRANSACTION ID',
    'AMOUNT',
    'METHOD',
    'STATUS',
    'TIMESTAMP',
    'PAY TYPE',
  ];

  static const List<double> _minWidths = [
    148, // ORDER ID
    148, // CUSTOMER ID
    100, // AMOUNT
    110, // METHOD
    110, // STATUS
    180, // TIMESTAMP
    130, // INITIATE REFUND
  ];

  @override
  void initState() {
    super.initState();
    _sorted = List.from(widget.transactions);
    _calculateWidths();
  }

  @override
  void didUpdateWidget(covariant _AnalyticsTable old) {
    super.didUpdateWidget(old);
    if (widget.transactions != old.transactions) {
      _sorted = List.from(widget.transactions);
      if (_sortColumnIndex != null) _sort(_sortColumnIndex!, _isAscending);
    }
  }

  void _calculateWidths() {
    _columnWidths = List.from(_minWidths);
  }

  void _sort(int colIndex, bool ascending) {
    _sorted.sort((a, b) {
      int cmp;
      switch (colIndex) {
        case 0:
          cmp = a.txnId.compareTo(b.txnId);
          break;
        case 1:
          cmp = a.orderId.compareTo(b.orderId);
          break;
        case 2:
          cmp = a.amount.compareTo(b.amount);
          break;
        case 3:
          cmp = a.paymentMethod.compareTo(b.paymentMethod);
          break;
        case 4:
          cmp = a.status.compareTo(b.status);
          break;
        case 5:
          cmp = a.txnTimestamp.compareTo(b.txnTimestamp);
          break;
        default:
          cmp = 0;
      }
      return ascending ? cmp : -cmp;
    });
    setState(() {
      _sortColumnIndex = colIndex;
      _isAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        // Expand widths to fill available space
        List<double> finalWidths = List.from(_columnWidths);
        double total = finalWidths.fold(0.0, (s, w) => s + w);
        if (total < maxWidth && finalWidths.isNotEmpty) {
          final extra = ((maxWidth - total - 2.0) / finalWidths.length)
              .floorToDouble();
          if (extra > 0) {
            for (int i = 0; i < finalWidths.length; i++) {
              finalWidths[i] += extra;
            }
          }
        }
        final tableWidth = finalWidths.fold(0.0, (s, w) => s + w);

        if (widget.transactions.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
            ),
            child: Column(
              children: [
                _buildTableHeader(finalWidths),
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: AppTheme.merchantIconGrey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No transactions found',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppTheme.merchantIconGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
              ],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
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
                      itemCount: _sorted.length,
                      itemBuilder: (context, index) =>
                          _buildDataRow(_sorted[index], index, finalWidths),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
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
      height: 52,
      child: Row(
        children: _headers.asMap().entries.map((entry) {
          final idx = entry.key;
          final header = entry.value;
          final isSortable = idx < 6; // last column not sortable
          return SizedBox(
            width: widths[idx],
            child: InkWell(
              onTap: isSortable
                  ? () => _sort(
                      idx,
                      _sortColumnIndex == idx ? !_isAscending : true,
                    )
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        header,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: AppTheme.merchantTableHeaderFont,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSortable && _sortColumnIndex == idx) ...[
                      const SizedBox(width: 4),
                      Icon(
                        _isAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 12,
                        color: AppTheme.merchantNavy,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDataRow(
    AnalyticsTransaction txn,
    int rowIdx,
    List<double> widths,
  ) {
    final isEven = rowIdx.isEven;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isEven
            ? AppTheme.merchantTableOddRow
            : AppTheme.merchantTableEvenRow,
        border: const Border(
          bottom: BorderSide(color: AppTheme.merchantBorder, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // ORDER ID (txnId)
          _cell(
            widths[0],
            Text(
              txn.txnId,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.merchantAccent,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // CUSTOMER ID (orderId)
          _cell(
            widths[1],
            Text(
              txn.orderId,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.merchantAccent,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // AMOUNT
          _cell(
            widths[2],
            Text(
              txn.formattedAmount,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.merchantTextDark,
              ),
            ),
          ),
          // METHOD
          _cell(
            widths[3],
            Text(
              txn.paymentMethod,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.merchantTextDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // STATUS chip
          _cell(
            widths[4],
            SizedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildStatusChip(txn.status),
                ),
              ),
            ),
          ),
          // TIMESTAMP
          _cell(
            widths[5],
            Text(
              txn.txnTimestamp.toString(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppTheme.merchantIconGrey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // INITIATE REFUND
          _cell(
            widths[6],

            Text(
              txn.payType.toString(),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.merchantTextBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg, fg;
    switch (status) {
      case 'SUCCESS':
        bg = AppTheme.merchantSuccessBg;
        fg = AppTheme.merchantSuccessText;
        break;
      case 'PENDING':
        bg = AppTheme.merchantWarningBg;
        fg = AppTheme.merchantWarningText;
        break;
      case 'FAILED':
        bg = AppTheme.merchantErrorBg;
        fg = AppTheme.merchantErrorText;
        break;
      default:
        bg = AppTheme.merchantPendingBg;
        fg = AppTheme.merchantPendingText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _cell(double width, Widget child) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Small helper model
// ─────────────────────────────────────────────────────────────────────────────

class _MetricCardData {
  final String title;
  final String value;
  // final double delta;
  final String deltaLabel;

  const _MetricCardData({
    required this.title,
    required this.value,
    // required this.delta,
    required this.deltaLabel,
  });
}
