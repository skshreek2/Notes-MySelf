
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

  late final PaymentAnalyticsBloc _paymentAnalyticsBloc;

  @override
  void initState() {
    super.initState();

    final dateRange = DateRangeHelper.getDateRange('YESTERDAY');

    final fromDate = dateRange.fromDate;
    final toDate = dateRange.toDate;

    _paymentAnalyticsBloc = PaymentAnalyticsBloc(
      context.read<PaymentAnalyticsRepository>(),
    )..add(LoadPaymentAnalytics(fromDate: fromDate, toDate: toDate));

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
  }

  @override
  void dispose() {
    _paymentAnalyticsBloc.close();
    _searchController.dispose();
    _entryController.dispose();
    super.dispose();
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

    return BlocProvider.value(
      value: _paymentAnalyticsBloc,
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
                onTap:
                    // () => setState(() => _selectedFilter = f)
                    () {
                      if (_selectedFilter == f) return;
                      setState(() {
                        _selectedFilter = f;
                      });
                      final dateRange = DateRangeHelper.getDateRange(f);

                      final fromDate = dateRange.fromDate;
                      final toDate = dateRange.toDate;

                      _paymentAnalyticsBloc.add(
                        LoadPaymentAnalytics(
                          fromDate: fromDate,
                          toDate: toDate,
                        ),
                      );
                    },
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
