import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';
import 'package:hdfc_merchant_app/features/dashboard/ui/widgets/PieChartPage.dart';
import 'package:hdfc_merchant_app/features/dashboard/ui/widgets/horizontal_bar_chart_page.dart';
import 'package:hdfc_merchant_app/features/dashboard/ui/widgets/line_chart_page.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/bloc/payment_analytics_bloc.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/bloc/payment_analytics_event.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/bloc/payment_analytics_state.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/data/payment_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../reports/ui/schedule_reports_dialog.dart';
import '../../payment_link/ui/create_payment_link_dialog.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen>
    with TickerProviderStateMixin {
  String _selectedFilter = 'Yesterday';
  String _selectedMetric = 'Total Transactions';
  final TextEditingController _searchController = TextEditingController();

  late final AnimationController _entryController;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Create staggered animations for 5 sections
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // All colors sourced from AppTheme merchant tokens
    final navy = AppTheme.merchantNavy;
    final accent = AppTheme.merchantAccent;
    final barBg = AppTheme.merchantBarBg;
    final barFill = AppTheme.merchantBarFill;
    final textDark = AppTheme.merchantTextDark;
    final textGrey = AppTheme.merchantTextGrey;
    final border = AppTheme.merchantBorder;

    return BlocProvider<PaymentAnalyticsBloc>(
      create: (context) =>
          PaymentAnalyticsBloc(context.read<PaymentAnalyticsRepository>())
            ..add(LoadPaymentAnalytics(filter: 'YESTERDAY')),
      child: BlocBuilder<PaymentAnalyticsBloc, PaymentAnalyticsState>(
        builder: (context, state) {
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
                      padding: const EdgeInsets.fromLTRB(48, 48, 48, 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _animatedSection(
                            0,
                            _buildHeaderRow(navy, textDark, textGrey, border),
                          ),
                          const SizedBox(height: 28),

                          _animatedSection(
                            1,
                            _buildMetricsRow(navy, textDark, textGrey, border),
                          ),
                          const SizedBox(height: 28),

                          _animatedSection(
                            2,
                            _buildMiddleRow(
                              navy,
                              accent,
                              textDark,
                              textGrey,
                              border,
                              barBg,
                              barFill,
                            ),
                          ),
                          const SizedBox(height: 28),

                          _animatedSection(
                            3,
                            _buildBottomRow(
                              navy,
                              accent,
                              textDark,
                              textGrey,
                              border,
                            ),
                          ),
                          const SizedBox(height: 28),

                          _animatedSection(
                            4,
                            _buildMerchantResourceCentre(
                              accent,
                              textDark,
                              border,
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

          return const SizedBox.shrink();
        },
      ),
    );

    // Stack(
    //   children: [
    //     Container(
    //       width: double.infinity,
    //       height: double.infinity,
    //       // decoration: const BoxDecoration(gradient: AppTheme.merchantBgGradient),
    //       decoration: BoxDecoration(
    //         gradient: LinearGradient(
    //           begin: Alignment.topLeft,
    //           end: Alignment.bottomRight,
    //           colors: [
    //             const Color(0xFFEFF6FF).withValues(alpha: 1.0),
    //             const Color(0xFFFAF5FF).withValues(alpha: 1.0),
    //           ],
    //         ),
    //       ),
    //     ),

    //     Container(
    //       decoration: const BoxDecoration(
    //         gradient: AppTheme.merchantBgGradient,
    //       ),
    //       child: SingleChildScrollView(
    //         padding: const EdgeInsets.fromLTRB(48, 48, 48, 48),
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             _animatedSection(
    //               0,
    //               _buildHeaderRow(navy, textDark, textGrey, border),
    //             ),
    //             const SizedBox(height: 28),
    //             _animatedSection(
    //               1,
    //               _buildMetricsRow(navy, textDark, textGrey, border),
    //             ),
    //             const SizedBox(height: 28),
    //             _animatedSection(
    //               2,
    //               _buildMiddleRow(
    //                 navy,
    //                 accent,
    //                 textDark,
    //                 textGrey,
    //                 border,
    //                 barBg,
    //                 barFill,
    //               ),
    //             ),
    //             const SizedBox(height: 28),
    //             _animatedSection(
    //               3,
    //               _buildBottomRow(navy, accent, textDark, textGrey, border),
    //             ),
    //             const SizedBox(height: 28),
    //             _animatedSection(
    //               4,
    //               _buildMerchantResourceCentre(accent, textDark, border),
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //   ],
    // );
  }

  Widget _animatedSection(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(position: _slideAnimations[index], child: child),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER: Greeting + interactive Time Filters
  // ─────────────────────────────────────────────
  Widget _buildHeaderRow(
    Color navy,
    Color textDark,
    Color textGrey,
    Color border,
  ) {
    const filters = ['Yesterday', 'Today', 'Weekly', 'Monthly', 'Custom'];
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        Text(
          'Good Morning Trisha!',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
          decoration: BoxDecoration(
            color: AppTheme.merchantCardBg,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppTheme.merchantBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: filters.map((f) {
              final isSelected = f == _selectedFilter;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.merchantAccent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    f,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.white : textGrey,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w600,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // 5 METRIC CARDS
  // ─────────────────────────────────────────────
  Widget _buildMetricsRow(
    Color navy,
    Color textDark,
    Color textGrey,
    Color border,
  ) {
    return LayoutBuilder(
      builder: (context, c) {
        // final w = (c.maxWidth - 4 * 16.0) / 5;
        final w = ((c.maxWidth) / 5) - 24;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          // crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _metricCard(
              'Total Transactions',
              '1,284',
              navy,
              textDark,
              textGrey,
              border,
              w,
              image: 'assets/images/receipt_3d.png',
              onTap: () => context.go('/transactions'),
            ),
            SizedBox(width: 24),
            _metricCard(
              'Success Rate',
              '92.6%',
              navy,
              textDark,
              textGrey,
              border,
              w,
            ),
            SizedBox(width: 24),
            _metricCard(
              'Refund Transactions',
              '₹30,000',
              navy,
              textDark,
              textGrey,
              border,
              w,
            ),
            SizedBox(width: 24),
            _metricCard(
              'Total Processed Amount',
              '₹8,72,450',
              navy,
              textDark,
              textGrey,
              border,
              w,
            ),
            SizedBox(width: 24),
            _metricCard(
              'Total Settled Amount',
              '₹8,52,450',
              navy,
              textDark,
              textGrey,
              border,
              w,
            ),
          ],
        );
      },
    );
  }

  // Widget _metricCard(String title, String value, Color navy, Color textDark, Color textGrey, Color border, double width, {String? image, VoidCallback? onTap}) {
  //   final isSelected = _selectedMetric == title;
  //   return GestureDetector(
  //     onTap: () {
  //       setState(() => _selectedMetric = title);
  //       if (onTap != null) onTap();
  //     },
  //     child: MouseRegion(
  //       cursor: SystemMouseCursors.click,
  //       child: Container(
  //         width: width, height: 130,
  //         padding: const EdgeInsets.all(24),
  //         decoration: BoxDecoration(
  //           color: isSelected ? const Color(0xFF002B6B) : Colors.white,
  //           borderRadius: BorderRadius.circular(24),
  //           border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0), width: 1),
  //           boxShadow: isSelected ? [
  //             BoxShadow(
  //               color: const Color(0xFF002B6B).withOpacity(0.15),
  //               blurRadius: 30,
  //               offset: const Offset(0, 12),
  //             ),
  //           ] : null,
  //         ),
  //         child: Stack(children: [
  //           Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
  //             Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 16, color: isSelected ? Colors.white70 : textGrey, fontWeight: FontWeight.w500)),
  //             const SizedBox(height: 8),
  //             Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : textDark)),
  //           ]),
  //           if (image != null && isSelected)
  //             Positioned(
  //               right: -5, bottom: -5,
  //               child: Image.asset(image, height: 80, fit: BoxFit.contain),
  //             ),
  //         ]),
  //       ),
  //     ),
  //   );
  // }

  Widget _metricCard(
    String title,
    String value,
    Color navy,
    Color textDark,
    Color textGrey,
    Color border,
    double width, {
    String? image,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedMetric == title;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedMetric = title);
        if (onTap != null) onTap();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: width,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: isSelected
                ? null
                : Border.all(color: AppTheme.merchantBorder, width: 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.merchantNavy.withValues(alpha: 0.05),
                      blurRadius: 30,
                      spreadRadius: 0,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Base background
                Container(
                  color: isSelected
                      ? Colors.transparent
                      : AppTheme.merchantCardBg,
                ),

                // Gradient overlay only for selected card
                if (isSelected)
                  Container(
                    decoration: const BoxDecoration(
                      //Boarder
                      gradient: AppTheme.merchantCardGradient,
                    ),
                  ),
                if (image != null && isSelected)
                  Container(
                    margin: EdgeInsets.fromLTRB((width - 64), 45, 5, 7),
                    child: Image.asset(
                      'assets/images/receipt_3d.png',
                      height: 60,
                      width: 60,
                      fit: BoxFit.contain,
                    ),
                  ),

                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 14,
                                  color: isSelected ? Colors.white : textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            value,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : textDark,
                                ),
                          ),
                        ],
                      ),

                      // if (image != null && isSelected)
                      // Positioned(
                      //   right: -5,
                      //   bottom: 7,
                      //   child: Image.asset(
                      //     image,
                      //     height: 60,
                      //     width: 60,
                      //     fit: BoxFit.contain,
                      //   ),
                      // ),
                      // Positioned(
                      //   right: -5,
                      //   bottom: 7,
                      //   child: SizedBox(
                      //     height: 60,
                      //     child: Transform.rotate(
                      //       angle: 0 * math.pi / 180,
                      //       child: AspectRatio(
                      //         aspectRatio: 1 / 1,
                      //         child: Image.asset(
                      //           height: 60,
                      //           width: 60,
                      //           'assets/images/receipt_3d.png',
                      //           fit: BoxFit.contain,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),

                      // Container(
                      //   margin: const EdgeInsets.fromLTRB(158, 45, 5, 7),
                      //   child: Image.asset(
                      //     'assets/images/receipt_3d.png',
                      //     height: 60,
                      //     width: 60,
                      //     fit: BoxFit.contain,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MIDDLE: Payment Volume Table + Quick Links
  // ─────────────────────────────────────────────
  Widget _buildMiddleRow(
    Color navy,
    Color accent,
    Color textDark,
    Color textGrey,
    Color border,
    Color barBg,
    Color barFill,
  ) {
    return SizedBox(
      height: 380,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _paymentVolumeCard(
              textDark,
              textGrey,
              border,
              barBg,
              barFill,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(flex: 2, child: _quickLinksCard(navy, textDark, border)),
        ],
      ),
    );
  }

  Widget _paymentVolumeCard(
    Color textDark,
    Color textGrey,
    Color border,
    Color barBg,
    Color barFill,
  ) {
    return _card(
      border: border,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Payment Method by Volume',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.merchantTextDark,
            ),
          ),
          const Expanded(child: HorizontalBarChartPage()),
        ],
      ),
    );
  }

  Widget _quickLinksCard(Color navy, Color textDark, Color border) {
    return _card(
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
                  'Settlements',
                  'assets/icons/settlements_icon.png',
                  navy,
                  textDark,
                  border,
                  () => context.go('/refunds'),
                ),
                Divider(height: 1, color: border),
                _qlRow(
                  'Payment Links',
                  'assets/icons/payment_links_icon.png',
                  navy,
                  textDark,
                  border,
                  () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withOpacity(0.4),
                      builder: (context) => const CreatePaymentLinkDialog(),
                    );
                  },
                  onDoubleTap: () => context.go('/payment-links'),
                ),
                Divider(height: 1, color: border),
                _qlRow(
                  'Reports',
                  'assets/icons/reports_icon.png',
                  navy,
                  textDark,
                  border,
                  () => context.go('/mpr'),
                ),
                Divider(height: 1, color: border),
                _qlRow(
                  'Orders',
                  'assets/icons/orders_icon.png',
                  navy,
                  textDark,
                  border,
                  () => context.go('/payment-links'),
                ),
                Divider(height: 1, color: border),
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
                  'Credit Adjustment',
                  'assets/icons/reports_icon.png',
                  navy,
                  textDark,
                  border,
                  () => context.go('/credit-adjustment'),
                ),
                Divider(height: 1, color: border),
                _qlRow(
                  'CMS-DMS',
                  'assets/icons/payment_links_icon.png',
                  navy,
                  textDark,
                  border,
                  () => context.go('/cms-dms'),
                ),
                Divider(height: 1, color: border),
                _qlRow(
                  'Analytics',
                  'assets/icons/orders_icon.png',
                  navy,
                  textDark,
                  border,
                  () => context.go('/analytics'),
                ),
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

  // ─────────────────────────────────────────────
  // BOTTOM ROW: Avg Ticket | Pie | Reports CTA
  // ─────────────────────────────────────────────
  Widget _buildBottomRow(
    Color navy,
    Color accent,
    Color textDark,
    Color textGrey,
    Color border,
  ) {
    return SizedBox(
      height: 440,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 4, child: _avgTicketCard(textDark, textGrey, border)),
          const SizedBox(width: 20),
          Expanded(flex: 3, child: _pieChartCard(textDark, textGrey, border)),
          const SizedBox(width: 20),
          Expanded(
            flex: 3,
            child: _reportsCTACard(navy, accent, textDark, textGrey, border),
          ),
        ],
      ),
    );
  }

  Widget _avgTicketCard(Color textDark, Color textGrey, Color border) {
    return _card(
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Average Ticket Size',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '1,458',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const SizedBox(height: 24),
          // const SizedBox(height: 32),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 0, bottom: 20, right: 10),
              child: LineChartPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pieChartCard(Color textDark, Color textGrey, Color border) {
    const segments = [
      _PieSegment('UPI', AppTheme.merchantChartPie0, 43),
      _PieSegment('Cards', AppTheme.merchantChartPie1, 28),
      _PieSegment('NetBanking', AppTheme.merchantChartPie2, 13),
      _PieSegment('Wallets', AppTheme.merchantChartPie3, 16),
    ];
    return _card(
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Payment Methods',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: SizedBox(width: 240, height: 240, child: PieChartPage()),
            ),
          ),
          const SizedBox(height: 24),
          // Single row legend wrapped for responsive layouts
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: segments
                .map(
                  (s) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          color: textGrey,
                          fontWeight: FontWeight.w500,
                          height: 1.36,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _reportsCTACard(
    Color navy,
    Color accent,
    Color textDark,
    Color textGrey,
    Color border,
  ) {
    return Stack(
      children: [
        _card(
          border: border,
          // color: AppTheme.merchantBgLightGrey,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Make it easy with\nReports Scheduling',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Automate report delivery via email\ndaily, weekly, or monthly',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: "Inter",
                      fontSize: 12,
                      // fontWeight: FontWeight.w600,
                      fontWeight: FontWeight.w500,
                      color: textGrey,
                      height: 1.33,
                      fontStyle: FontStyle.normal,
                      letterSpacing: 0,
                    ),
                  ),

                  // Text('Automate report delivery via email\ndaily, weekly, or monthly',
                  //     style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12,fontWeight: FontWeight.w500, color: textDark , height: 1.9, fontStyle: FontStyle.normal, letterSpacing: 0)),
                  // Text('Automate report delivery via email\ndaily, weekly, or monthly',
                  //     style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12,fontWeight: FontWeight.w500, color: textDark , height: 1.9, fontStyle: FontStyle.normal, letterSpacing: 0)),
                  Expanded(child: const SizedBox(height: 24)),
                  GestureDetector(
                    // onTap: () => context.go('/mpr'),
                    onTap: () => {
                      // context.go('/mpr')
                      showGeneralDialog(
                        context: context,
                        barrierLabel: 'Schedule Reports',
                        barrierDismissible: true,
                        barrierColor: Colors.black54,
                        transitionDuration: const Duration(milliseconds: 250),
                        pageBuilder: (ctx, anim1, anim2) {
                          return SafeArea(
                            child: Material(
                              color: Colors.transparent,
                              child: ScheduleReportsDialog(),
                            ),
                          );
                        },
                      ),
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Start Scheduling',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_circle_right_outlined,
                            color: accent,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Positioned(
              //   left: 172, bottom: -7,
              //   child: Image.asset('assets/images/calendar_3d.png', height: 208,width: 208, fit: BoxFit.contain, ),
              // ),
            ],
          ),
        ),
        Positioned(
          left: 205,
          bottom: -2,
          child: Image.asset(
            'assets/images/calendar_3d.png',
            height: 208,
            width: 208,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // MERCHANT RESOURCE CENTRE
  // ─────────────────────────────────────────────
  Widget _buildMerchantResourceCentre(
    Color accent,
    Color textDark,
    Color border,
  ) {
    return SizedBox(
      height: 200,
      child: _card(
        border: border,
        // padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'The Merchant\nResource Centre',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: AppTheme.merchantTextDark,
                      letterSpacing: -0.72,
                      fontFamily: "Inter",
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'View More',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Container(width: 1.5, color: border.withValues(alpha: 0.8)),
            // const SizedBox(width: 40),
            // Row(
            //   children: [
            //     Expanded(child: _resourceItem('One platform for\neverything', accent, textDark, border)),
            //     Expanded(child: _resourceItem('View statements\nin one click', accent, textDark, border)),
            //     Expanded(child: _resourceItem('Understanding\nsettlement cycles', accent, textDark, border)),
            //   ],
            // ),
            // Expanded(child: SizedBox()),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _resourceItem(
                    'One platform for\neverything',
                    accent,
                    textDark,
                    border,
                  ),
                  _resourceItem(
                    'View statements\nin one click',
                    accent,
                    textDark,
                    border,
                  ),
                  _resourceItem(
                    'Understanding\nsettlement cycles',
                    accent,
                    textDark,
                    border,
                  ),
                ],
              ),
            ),
            // const SizedBox(width: 24),
            SizedBox(
              width: 180,
              height: 140,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -79.752,
                    bottom: -99.473,
                    child: SizedBox(
                      width: 352,
                      child: Transform.rotate(
                        angle: 0 * math.pi / 180,
                        child: AspectRatio(
                          aspectRatio: 44 / 39,
                          child: Image.asset(
                            'assets/images/resource_3d.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // SizedBox(
            //   width: 180,
            //   child: Stack(
            //     alignment: Alignment.center,
            //     children: [
            //       const SizedBox(height: 140),
            //       Positioned(
            //         right: -20, bottom: -20,
            //         child: Image.asset('assets/images/resource_3d.png', height: 180, fit: BoxFit.contain),
            //       ),
            //     ],
            //   ),
            // ),

            // SizedBox(
            //   width: 352,
            //   height: 312,
            //   child: Stack(
            //     clipBehavior: Clip.none,
            //     children: [
            //       Positioned(
            //         right: -99.752,
            //         bottom: -99.752,
            //         child: SizedBox(
            //           height: 312,
            //           width: 352,
            //           child: Transform.rotate(
            //             angle: 0,
            //             child: AspectRatio(
            //               aspectRatio: 44 / 39,
            //               child: Image.asset(
            //                 'assets/images/resource_3d.png',
            //                 fit: BoxFit.contain,
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // )
          ],
        ),
      ),
    );
  }

  Widget _resourceItem(
    String text,
    Color accent,
    Color textDark,
    Color border,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Row(
        // spacing: 16,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 80,
            margin: const EdgeInsets.only(right: 16, left: 16),
            decoration: BoxDecoration(
              color: AppTheme.merchantBulletLightBlue,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontFamily: "Inter",
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: AppTheme.merchantTextDark,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SHARED CARD WRAPPER
  // ─────────────────────────────────────────────
  Widget _card({
    required Widget child,
    required Color border,
    Color? color,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: color ?? AppTheme.merchantCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.merchantBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.merchantNavy.withValues(alpha: 0.05),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────
class _PieSegment {
  final String label;
  final Color color;
  final int pct;
  const _PieSegment(this.label, this.color, this.pct);
}

// ─────────────────────────────────────────────
// CUSTOM PAINTERS
// ─────────────────────────────────────────────
class _AreaChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final yPts = [
      0.20,
      0.30,
      0.25,
      0.40,
      0.38,
      0.55,
      0.45,
      0.65,
      0.52,
      0.70,
      0.75,
      0.90,
    ];
    List<Offset> pts = [];
    for (int i = 0; i < yPts.length; i++) {
      pts.add(
        Offset(
          i / (yPts.length - 1) * size.width,
          size.height - yPts[i] * size.height,
        ),
      );
    }

    // Smooth bezier path
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      path.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        pts[i + 1].dx,
        pts[i + 1].dy,
      );
    }

    // Gradient fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.merchantChartPie2.withValues(alpha: 0.45),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    // Stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.merchantAccent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Grid lines & Axis Labels
    final gridPaint = Paint()
      ..color = AppTheme.merchantBorder.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    final textStyle = TextStyle(
      color: AppTheme.merchantTextGrey,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    final yLabels = ['100k', '50k', '20k', '10k', '0'];

    for (int i = 0; i < 5; i++) {
      final h = size.height * i / 4;
      canvas.drawLine(Offset(0, h), Offset(size.width, h), gridPaint);

      final tp = TextPainter(
        text: TextSpan(text: yLabels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width - 8, h - tp.height / 2));
    }

    final xLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'July',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];
    for (int i = 0; i < xLabels.length; i++) {
      final w = size.width * i / (xLabels.length - 1);
      final tp = TextPainter(
        text: TextSpan(text: xLabels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(w - tp.width / 2, size.height + 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _DonutChartPainter extends CustomPainter {
  final List<_PieSegment> segments;
  final bool labelOutside;
  const _DonutChartPainter(this.segments, {this.labelOutside = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const donutThickness = 65.0; // Thick donut as per PNG
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - donutThickness / 2,
    );

    double startAngle = -pi / 2;

    // 1. Draw Donut Segments (Solid, no gaps)
    for (final seg in segments) {
      final sweepAngle = (seg.pct / 100) * (2 * pi);

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = donutThickness;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    // 2. Draw Floating Percentage Chips
    startAngle = -pi / 2;
    for (final seg in segments) {
      final sweepAngle = (seg.pct / 100) * (2 * pi);
      final midAngle = startAngle + sweepAngle / 2;

      // Position the chip centered on the arc
      final labelRadius = radius - donutThickness / 2;
      final lx = center.dx + labelRadius * cos(midAngle);
      final ly = center.dy + labelRadius * sin(midAngle);

      // Draw white rounded rect (chip)
      const chipW = 54.0;
      const chipH = 34.0;
      final chipRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(lx, ly), width: chipW, height: chipH),
        const Radius.circular(10),
      );

      canvas.drawRRect(
        chipRect,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );

      // Draw percentage text inside chip
      final tp = TextPainter(
        text: TextSpan(
          text: '${seg.pct}%',
          style: TextStyle(
            color: AppTheme.merchantTextGrey,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
