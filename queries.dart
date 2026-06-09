

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


    _paymentAnalyticsBloc = PaymentAnalyticsBloc(
      context.read<PaymentAnalyticsRepository>(),
    )..add(LoadPaymentAnalytics(filter: 'YESTERDAY'));


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

on change yesterday, today make api call (bloc provider)
