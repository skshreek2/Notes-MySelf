import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';
import 'package:hdfc_merchant_app/core/responsive_break_points.dart';
import 'package:hdfc_merchant_app/core/util/common.dart';
import 'package:hdfc_merchant_app/core/util/constant_values.dart';
import 'package:hdfc_merchant_app/core/util/nullable_extensions.dart';
import 'package:hdfc_merchant_app/features/auth/bloc/auth_keys_bloc.dart';
import 'package:hdfc_merchant_app/features/auth/bloc/auth_keys_state.dart';
import 'package:hdfc_merchant_app/features/configs/sessionmgmt/session_manager.dart'
    show SessionManager;
import 'package:hdfc_merchant_app/features/dashboard/ui/widgets/bottom_row.dart';
import 'package:hdfc_merchant_app/features/dashboard/ui/widgets/card_view.dart';
import 'package:hdfc_merchant_app/features/dashboard/ui/widgets/horizontal_bar_chart_page.dart';
import 'package:hdfc_merchant_app/features/dashboard/ui/widgets/metric_card.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/bloc/dashboard_filter_cubit.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/bloc/dashboard_filter_state.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/bloc/payment_analytics_bloc.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/bloc/payment_analytics_event.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/bloc/payment_analytics_state.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/data/payment_response_model.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/utils/date_range.dart';
import 'package:hdfc_merchant_app/shared/calender/bloc/date_picker_cubit.dart';
import 'package:hdfc_merchant_app/shared/widgets/common_date_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../reports/ui/schedule_reports_dialog.dart';
import '../../../core/util/shared_prefs.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen>
    with TickerProviderStateMixin {
  String _selectedMetric = 'Total Transactions';
  final TextEditingController _searchController = TextEditingController();

  late final AnimationController _entryController;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;
  bool _shouldLoadDashboard = false;
  bool _dashboardCalled = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimations = List.generate(5, (index) {
      return CurvedAnimation(
        parent: _entryController,
        curve: Interval(0.1 * index, 0.4 + 0.1 * index, curve: Curves.easeOut),
      );
    });

    _slideAnimations = List.generate(5, (index) {
      return Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(
            0.1 * index,
            0.4 + 0.1 * index,
            curve: Curves.easeOut,
          ),
        ),
      );
    });

    _entryController.forward();

    _checkSessionAndSetFlag();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _checkSessionAndSetFlag() {
    final sessionId = SessionManager.instance.sessionId;

    if (sessionId == null) {
      Future.delayed(Duration.zero, () {
        context.read<AuthKeysBloc>().stream.listen((authKeysState) {
          if (authKeysState is AuthKeysLoaded) {
            Future.delayed(Duration(milliseconds: 100), () {
              // debugPrint('AuthKeys loaded + delay - triggering dashboard');
              setState(() => _shouldLoadDashboard = true);
            });
          }
        });
      });
    } else {
      // debugPrint('Session found: $sessionId - loading dashboard immediately');
      setState(() => _shouldLoadDashboard = true);
    }
  }

  void _loadDashboard(BuildContext context) {
    final filterDateRange = context.read<DashboardFilterCubit>().state;

    final dateRange = DateRangeHelper.getDateRange(filterDateRange.dateRange);
    final fromDate = dateRange.fromDate;
    final toDate = dateRange.toDate;

    context.read<PaymentAnalyticsBloc>().add(
      LoadPaymentAnalytics(fromDate: fromDate, toDate: toDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navy = AppTheme.merchantNavy;
    final accent = AppTheme.merchantAccent;
    final barBg = AppTheme.merchantBarBg;
    final barFill = AppTheme.merchantBarFill;
    final textDark = AppTheme.merchantTextDark;
    final textGrey = AppTheme.merchantTextGrey;
    final border = AppTheme.merchantBorder;

    return BlocBuilder<PaymentAnalyticsBloc, PaymentAnalyticsState>(
      builder: (context, state) {
        if (_shouldLoadDashboard && !_dashboardCalled) {
          _shouldLoadDashboard = false;
          _dashboardCalled = true;
          _loadDashboard(context);
        }

        // final screenType = ResponsiveBreakPoints.of(context);

        if (state is PaymentAnalyticsLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is PaymentAnalyticsError) {
          return Scaffold(body: Center(child: Text(state.message)));
        }

        if (state is PaymentAnalyticsLoaded) {
          final data = state.data;
          bool isMobile = ResponsiveBreakPoints.isMobile(context);
          return Scaffold(
            body: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEFF6FF), Color(0xFFFAF5FF)],
                    ),
                  ),
                ),

                Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.merchantBgGradient,
                  ),
                  child: SingleChildScrollView(
                    padding: isMobile
                        ? const EdgeInsets.all(15)
                        : const EdgeInsets.all(48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _animatedSection(
                          0,
                          _buildHeaderRow(
                            navy,
                            textDark,
                            textGrey,
                            border,
                            context,
                          ),
                        ),
                        const SizedBox(height: 28),

                        _animatedSection(
                          1,
                          _buildMetricsRow(
                            data.summary!,
                            navy,
                            textDark,
                            textGrey,
                            border,
                          ),
                        ),
                        const SizedBox(height: 28),

                        _animatedSection(
                          2,
                          _buildMiddleRow(
                            data.paymentMethodVolume!,
                            navy,
                            accent,
                            textDark,
                            textGrey,
                            border,
                            barBg,
                            barFill,
                            isMobile,
                          ),
                        ),
                        const SizedBox(height: 28),

                        _animatedSection(
                          3,
                          BottomRow(
                            data: data,
                            navy: navy,
                            accent: accent,
                            textDark: textDark,
                            textGrey: textGrey,
                            border: border,
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
    // );
  }

  Widget _animatedSection(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(position: _slideAnimations[index], child: child),
    );
  }

  String timeBasedGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    // if (hour < 20) return 'Good Evening';
    if (hour <= 24) return 'Good Evening';
    return 'Good Night';
  }

  Future<void> _openDatePicker() async {
    final datePickerCubit = context.read<DatePickerCubit>();
    final dashBloc = context.read<PaymentAnalyticsBloc>();

    final CommonDatePickerResult? result =
        await showDialog<CommonDatePickerResult>(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              backgroundColor: Colors.transparent,
              child: SizedBox(
                width: 320,
                child: CommonDatePicker(
                  onApply: (_, value) {
                    Navigator.of(dialogContext).pop(value);
                  },
                ),
              ),
            );
          },
        );

    if (!mounted || result == null) return;

    final startDate = DateFormat('yyyy-MM-dd').format(result.startDate);
    final endDate = DateFormat(
      'yyyy-MM-dd',
    ).format(result.endDate ?? result.startDate);

    datePickerCubit.setDateRange(
      DateTime.parse(startDate),
      DateTime.parse(endDate),
    );

    final formatter = DateFormat('dd MMM');
    context.read<DashboardFilterCubit>().changeDateRange(
      'Custom (${formatter.format(result.startDate)} - ${formatter.format(result.endDate)})',
    );
    dashBloc.add(LoadPaymentAnalytics(fromDate: startDate, toDate: endDate));
  }

  // ─────────────────────────────────────────────
  // HEADER: Greeting + interactive Time Filters
  // ─────────────────────────────────────────────
  Widget _buildHeaderRow(
    Color navy,
    Color textDark,
    Color textGrey,
    Color border,
    BuildContext context,
  ) {
    final filter = context.read<DashboardFilterCubit>().state;
    final selectedDateRangeLabel = filter.dateRange;
    final bool isCustomSelected = filter.dateRange.startsWith('Custom');
    final List<String> dropdownItems = isCustomSelected
        ? [
            'Today',
            'Yesterday',
            'Last 7 Days',
            'Last 15 Days',
            'Last 30 Days',
            selectedDateRangeLabel,
          ]
        : [
            'Today',
            'Yesterday',
            'Last 7 Days',
            'Last 15 Days',
            'Last 30 Days',
            'Custom',
          ];

    final textTheme = Theme.of(context).textTheme;
    bool isMobile = ResponsiveBreakPoints.isMobile(context);
    print("isMobile $isMobile");
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                SharedPrefs.getFullName().isNotEmpty
                    ? '${timeBasedGreeting()} ${SharedPrefs.getFullName()}!'
                    : '${timeBasedGreeting()}!',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                width: 220,
                // padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1),
                  color: const Color.fromRGBO(255, 255, 255, 0.40),
                ),
                child: BlocBuilder<DashboardFilterCubit, DashboardFilterState>(
                  builder: (context, state) {
                    return DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: state.dateRange,
                        borderRadius: BorderRadius.circular(12),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.5,
                        ),

                        items: dropdownItems.map((f) {
                          return DropdownMenuItem<String>(
                            value: f,
                            child: Text(f),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          if (value == null) return;

                          if (value == 'Custom') {
                            _openDatePicker();
                            return;
                          }

                          context.read<DashboardFilterCubit>().changeDateRange(
                            value,
                          );

                          final dateRange = DateRangeHelper.getDateRange(value);
                          final fromDate = dateRange.fromDate;
                          final toDate = dateRange.toDate;
                          context.read<PaymentAnalyticsBloc>().add(
                            LoadPaymentAnalytics(
                              fromDate: fromDate,
                              toDate: toDate,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                SharedPrefs.getFullName().isNotEmpty
                    ? '${timeBasedGreeting()} ${SharedPrefs.getFullName()}!'
                    : '${timeBasedGreeting()}!',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),

              Container(
                width: filter.dateRange.startsWith('Custom') ? 220 : 160,
                // padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1),
                  color: const Color.fromRGBO(255, 255, 255, 0.40),
                ),
                child: BlocBuilder<DashboardFilterCubit, DashboardFilterState>(
                  builder: (context, state) {
                    return DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: state.dateRange,
                        borderRadius: BorderRadius.circular(12),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.5,
                        ),

                        items: dropdownItems.map((f) {
                          return DropdownMenuItem<String>(
                            value: f,
                            child: Text(f),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          if (value == null) return;

                          if (value == 'Custom') {
                            _openDatePicker();
                            return;
                          }

                          context.read<DashboardFilterCubit>().changeDateRange(
                            value,
                          );

                          final dateRange = DateRangeHelper.getDateRange(value);
                          final fromDate = dateRange.fromDate;
                          final toDate = dateRange.toDate;
                          context.read<PaymentAnalyticsBloc>().add(
                            LoadPaymentAnalytics(
                              fromDate: fromDate,
                              toDate: toDate,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }

  // ─────────────────────────────────────────────
  // 5 METRIC CARDS
  // ─────────────────────────────────────────────
  Widget _buildMetricsRow(
    PaymentSummaryModel summary,
    Color navy,
    Color textDark,
    Color textGrey,
    Color border,
  ) {
    bool isMobile = ResponsiveBreakPoints.isMobile(context);
    return LayoutBuilder(
      builder: (context, c) {
        // final w = (c.maxWidth - 4 * 16.0) / 5;
        final w = ((c.maxWidth) / 5) - 24;
        return isMobile
            ? Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  MetricCard(
                    title: totalTxns,
                    value:
                        (summary.totalTransactions == null ||
                            summary.totalTransactions == 0)
                        ? '—'
                        : summary.totalTransactions.toString(),
                    navy: navy,
                    textDark: textDark,
                    textGrey: textGrey,
                    border: border,
                    width: MediaQuery.of(context).size.width / 2 - 24,
                    image: 'assets/images/receipt_3d.png',
                    isSelected: _selectedMetric == totalTxns,
                    onTap: () {
                      setState(() => _selectedMetric = totalTxns);
                      context.go('/transaction-analytics');
                    },
                  ),
                  MetricCard(
                    title: successRate,
                    value:
                        (summary.successRate == null ||
                            summary.successRate == 0)
                        ? '—'
                        : '${summary.successRate}%',
                    navy: navy,
                    textDark: textDark,
                    textGrey: textGrey,
                    border: border,
                    width: MediaQuery.of(context).size.width / 2 - 24,
                    isSelected: _selectedMetric == successRate,
                    onTap: () {
                      setState(() => _selectedMetric = successRate);
                    },
                  ),
                  MetricCard(
                    title: refundTxns,
                    value:
                        (summary.refundTransactions == null ||
                            summary.refundTransactions == 0)
                        ? '—'
                        : '₹${summary.refundTransactions}',
                    navy: navy,
                    textDark: textDark,
                    textGrey: textGrey,
                    border: border,
                    width: MediaQuery.of(context).size.width / 2 - 24,
                    isSelected: _selectedMetric == refundTxns,
                    onTap: () {
                      setState(() => _selectedMetric = refundTxns);
                    },
                  ),
                  MetricCard(
                    title: totalProcessedAmnt,
                    value:
                        (summary.totalProcessedAmount == null ||
                            summary.totalProcessedAmount == 0)
                        ? '—'
                        : '₹ ${formatAmount(summary.totalProcessedAmount)}',
                    navy: navy,
                    textDark: textDark,
                    textGrey: textGrey,
                    border: border,
                    width: MediaQuery.of(context).size.width / 2 - 24,
                    isSelected: _selectedMetric == totalProcessedAmnt,
                    onTap: () {
                      setState(() => _selectedMetric = totalProcessedAmnt);
                    },
                  ),
                  MetricCard(
                    title: totalSettledAmnt,
                    value:
                        (summary.totalSettledAmount == null ||
                            summary.totalSettledAmount == 0)
                        ? '—'
                        : '₹${formatAmount(summary.totalSettledAmount)}',
                    navy: navy,
                    textDark: textDark,
                    textGrey: textGrey,
                    border: border,
                    width: MediaQuery.of(context).size.width / 2 - 24,
                    isSelected: _selectedMetric == totalSettledAmnt,
                    onTap: () {
                      setState(() => _selectedMetric = totalSettledAmnt);
                    },
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                // crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MetricCard(
                    title: totalTxns,
                    value:
                        (summary.totalTransactions == null ||
                            summary.totalTransactions == 0)
                        ? '—'
                        : summary.totalTransactions.toString(),

                    navy: navy,
                    textDark: textDark,
                    textGrey: textGrey,
                    border: border,
                    width: w,
                    image: 'assets/images/receipt_3d.png',
                    // onTap: () => context.go('/transaction-analytics'),
                    isSelected: _selectedMetric == totalTxns,
                    onTap: () {
                      setState(() => _selectedMetric = totalTxns);
                      context.go('/transaction-analytics');
                    },
                  ),
                  SizedBox(width: 24),
                  MetricCard(
                    title: successRate,
                    value:
                        (summary.successRate == null ||
                            summary.successRate == 0)
                        ? '—'
                        : '${summary.successRate.toString()}%',

                    navy: navy,
                    textDark: textDark,
                    textGrey: textGrey,
                    border: border,
                    width: w,
                    isSelected: _selectedMetric == successRate,
                    onTap: () {
                      setState(() => _selectedMetric = successRate);
                    },
                  ),
                  SizedBox(width: 24),
                  MetricCard(
                    title: refundTxns,
                    value:
                        (summary.refundTransactions == null ||
                            summary.refundTransactions == 0)
                        ? '—'
                        : '₹${summary.refundTransactions.toString()}',
                    navy: navy,
                    textDark: textDark,
                    textGrey: textGrey,
                    border: border,
                    width: w,
                    isSelected: _selectedMetric == refundTxns,
                    onTap: () {
                      setState(() => _selectedMetric = refundTxns);
                    },
                  ),
                  SizedBox(width: 24),
                  MetricCard(
                    title: totalProcessedAmnt,
                    value:
                        (summary.totalProcessedAmount == null ||
                            summary.totalProcessedAmount == 0)
                        ? '—'
                        : '₹ ${formatAmount(summary.totalProcessedAmount)}',

                    navy: navy,
                    textDark: textDark,
                    textGrey: textGrey,
                    border: border,
                    width: w,
                    isSelected: _selectedMetric == totalProcessedAmnt,
                    onTap: () {
                      setState(() => _selectedMetric = totalProcessedAmnt);
                    },
                  ),
                  SizedBox(width: 24),

                  MetricCard(
                    title: totalSettledAmnt,
                    value:
                        (summary.totalSettledAmount == null ||
                            summary.totalSettledAmount == 0)
                        ? '—'
                        : '₹${formatAmount(summary.totalSettledAmount)}',
                    navy: navy,
                    textDark: textDark,
                    textGrey: textGrey,
                    border: border,
                    width: w,
                    isSelected: _selectedMetric == totalSettledAmnt,
                    onTap: () {
                      setState(() => _selectedMetric = totalSettledAmnt);
                    },
                  ),
                ],
              );
      },
    );
  }

  // ─────────────────────────────────────────────
  // MIDDLE: Payment Volume Table + Quick Links
  // ─────────────────────────────────────────────
  Widget _buildMiddleRow(
    List<PaymentMethodVolumeModel> paymentMethodVolume,
    Color navy,
    Color accent,
    Color textDark,
    Color textGrey,
    Color border,
    Color barBg,
    Color barFill,
    bool isMobile,
  ) {
    return SizedBox(
      height: 380,
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _paymentVolumeCard(
                    paymentMethodVolume,
                    textDark,
                    textGrey,
                    border,
                    barBg,
                    barFill,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: _quickLinksCard(navy, textDark, border),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _paymentVolumeCard(
                    paymentMethodVolume,
                    textDark,
                    textGrey,
                    border,
                    barBg,
                    barFill,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: _quickLinksCard(navy, textDark, border),
                ),
              ],
            ),
    );
  }

  Widget _paymentVolumeCard(
    List<PaymentMethodVolumeModel> paymentMethodVolume,
    Color textDark,
    Color textGrey,
    Color border,
    Color barBg,
    Color barFill,
  ) {
    return CardView(
      border: border,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            topPaymentMthds,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.merchantTextDark,
            ),
          ),
          Expanded(
            child: HorizontalBarChartPage(paymentvolume: paymentMethodVolume),
          ),
        ],
      ),
    );
  }

  Widget _quickLinksCard(Color navy, Color textDark, Color border) {
    return CardView(
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Links',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _qlRow(
                  'Transaction Analytics',
                  'assets/icons/settlements_icon.png',
                  navy,
                  textDark,
                  border,
                  () => context.go('/transaction-analytics'),
                ),
                Divider(height: 1, color: border),
                _qlRow(
                  'Payment Links',
                  'assets/icons/payment_links_icon.png',
                  navy,
                  textDark,
                  border,
                  () => context.go('/payment-links'),
                ),
                Divider(height: 1, color: border),
                _qlRow(
                  'Reports',
                  'assets/icons/reports_icon.png',
                  navy,
                  textDark,
                  border,
                  // () => context.go('/mpr'),
                  () => context.go('/reports'),
                ),
                Divider(height: 1, color: border),
                // _qlRow(
                //   'Orders',
                //   'assets/icons/orders_icon.png',
                //   navy,
                //   textDark,
                //   border,
                //   () => context.go('/payment-links'),
                // ),
                // Divider(height: 1, color: border),

                // _qlRow(
                //   'Credit Adjustment',
                //   'assets/icons/reports_icon.png',
                //   navy,
                //   textDark,
                //   border,
                //   () => context.go('/credit-adjustment'),
                // ),
                // Divider(height: 1, color: border),
                // _qlRow(
                //   'CMS-DMS',
                //   'assets/icons/payment_links_icon.png',
                //   navy,
                //   textDark,
                //   border,
                //   () => context.go('/cms-dms'),
                // ),
                // Divider(height: 1, color: border),
                // _qlRow(
                //   'Analytics',
                //   'assets/icons/orders_icon.png',
                //   navy,
                //   textDark,
                //   border,
                //   () => context.go('/analytics'),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qlRow(
    String title,
    String assetPath,
    Color navy,
    Color textDark,
    Color border,
    VoidCallback onTap, {
    VoidCallback? onDoubleTap,
  }) {
    return InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: AppTheme.merchantIconGradient,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.transparent,
                    offset: Offset(0, 4),
                    blurRadius: 6,
                    spreadRadius: -1,
                  ),
                  BoxShadow(
                    color: Colors.transparent,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Image.asset(
                assetPath,
                color: Colors.white,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
            ),
            // 'assets/icons/payment_links_icon.png',
            const ImageIcon(
              AssetImage('assets/icons/vector.png'),
              color: AppTheme.merchantIconGrey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
