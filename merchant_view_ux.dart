import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hdfc_merchant_app/core/util/common.dart';
import 'package:hdfc_merchant_app/core/util/gif_progressbar.dart';
import 'package:hdfc_merchant_app/features/dashboard/presentation/graphs/weekly_volume_chart.dart';
import 'package:hdfc_merchant_app/features/dashboard/presentation/widgets/failure_widget.dart';
import 'package:hdfc_merchant_app/features/dashboard/presentation/widgets/loading_widget.dart';
import 'package:hdfc_merchant_app/features/payments/bloc/orders_bloc.dart';
import 'package:hdfc_merchant_app/features/payments/data/orders_entity.dart';
import 'package:hdfc_merchant_app/features/payments/data/orders_repository.dart';
import 'package:hdfc_merchant_app/shared/calender/alendar_cubit.dart';
import 'package:hdfc_merchant_app/shared/calender/widgets/global_calendar_toggle.dart';
import 'package:intl/intl.dart';
import 'dart:async' show Timer;

class MerchantDashboardScreen extends StatelessWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              OrdersBloc(repository: OrdersRepository())..add(const OrdersFetched(isDashBoard: true)),
        ),
        BlocProvider(
          create: (context) => CalendarCubit(),
        ),
      ],
      child: const MerchantDashboardView(), // ✅ View INSIDE Provider
    );
  }
}

class MerchantDashboardView extends StatefulWidget {
  const MerchantDashboardView({super.key});
  
  @override
  State<MerchantDashboardView> createState() => _MerchantDashboardViewState();
}

class ChartType {
  static const bar = 0;
  static const line = 1;
}
class _MerchantDashboardViewState extends State<MerchantDashboardView>
    with TickerProviderStateMixin {

     late AnimationController _controller ;



    late AnimationController _dailyController; 
    late Animation<double> _dailyAnimation; 
  // ✅ SAME Animation state - NOTHING CHANGED
  List<double> weeklyVolumeHeights = [];
  List<double> statusHeights = [];
  List<FlSpot> revenuePoints = [];
  List<FlSpot> dailyPoints = [];

  int touchedSuccessIndex = -1;
  int touchedPaymentIndex = -1;
  int touchedWeeklyBarIndex = -1;
  int touchedStatusBarIndex = -1;

  bool weeklyAnimComplete = false;
  bool statusAnimComplete = false;
  bool revenueAnimComplete = false;
  bool dailyAnimComplete = false;
  bool isPlaying = false;

  int _weeklyType = ChartType.line;

  Timer? _revenueTimer;
  Timer? _dailyTimer;
  Timer? _weeklyVolumeTimer;
  Timer? _statusTimer;
  
//List<Timer> allDailyTimers = [];

@override
void deactivate() {
  
  super.deactivate();

 
}
// ignore: must_call_super
@override
void dispose(){
  
  _revenueTimer?.cancel();
  _dailyTimer?.cancel();
  _weeklyVolumeTimer?.cancel();
  _statusTimer?.cancel();

   _dailyController.dispose();
super.dispose(); 
  
}
  
  @override
  void initState() {
    super.initState();
    
    //  _controller = AnimationController(
    //   duration: const Duration(milliseconds: 1200),
    //   vsync: this,
    // );

    _dailyController = AnimationController(
      duration: const Duration(milliseconds: 2400),  // Match revenue duration
      vsync: this,
    );
    _dailyAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dailyController, curve: Curves.easeOutBack)
    );

   
  }

@override
Widget build(BuildContext context) {
   
  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: context.read<OrdersBloc>()),  // Existing OrdersBloc
      BlocProvider(create: (context) => CalendarCubit()),    // ✅ NEW CalendarCubit
    ],
     child: BlocListener<CalendarCubit, CalendarState>(  // ✅ ADD THIS
      listener: (context, calendarState) {
        // ✅ API CALL HAPPENS HERE after date selection!
        if (calendarState.startDate != null && 
            calendarState.endDate != null ) {
          
          
          // ✅ TRIGGER API CALL
          context.read<OrdersBloc>().add(
            OrdersDateRangeChanged(
              fromDate: calendarState.startDate!,
              toDate: calendarState.endDate!,
                isDashBoard: true
            ),
          );
        }
      },
    child: BlocConsumer<OrdersBloc, OrdersState>(
      listenWhen: (prev, curr) => curr is OrdersPaginationLoaded,
      listener: (context, state) {
        // ✅ Restart animations when new data loads (UNCHANGED)
        if (state is OrdersPaginationLoaded && !isPlaying) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                _resetAnimations();
                isPlaying = true;
              });
              
              _startAllAnimations();
            }
          });
        }
        if (state is OrdersFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${state.message}')),
          );
        }
      },
      builder: (context, ordersState) {
        // ✅ SAME loading/error states
        if (ordersState is OrdersInitial || ordersState is OrdersLoading) {
          return GifProgressBar();
        }

        if (ordersState is OrdersFailure) {
          return Failurewidget(errorMessage: ordersState.message);
        }

        // ✅ Filter orders by CalendarCubit date range
        final rawOrders = (ordersState as OrdersPaginationLoaded).orders;
        final calendarState = context.watch<CalendarCubit>().state;
        final filteredOrders = _filterOrdersByCalendar(rawOrders, calendarState);

        return _buildDashboardUI(filteredOrders, calendarState);
      },
    ),
     )
  );
}

// ✅ NEW: Filter orders by calendar date range
List<TransactionEntity> _filterOrdersByCalendar(
  List<TransactionEntity> orders,
  CalendarState calendarState,
) {
  if (calendarState.startDate == null || calendarState.endDate == null) {
    return orders;  // Show all orders if no date range selected
  }

  return orders.where((order) {
    return order.date.isAfter(calendarState.startDate!.subtract(const Duration(days: 1))) &&
           order.date.isBefore(calendarState.endDate!.add(const Duration(days: 1)));
  }).toList();
}

// ✅ UPDATED: Pass filtered orders + calendar state
Widget _buildDashboardUI(List<TransactionEntity> filteredOrders, CalendarState calendarState) {
  return Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth <= 800;

        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 GlobalCalendarToggle(top:1),
                 SizedBox(height: 15,),
                  // ✅ SAME Stat Cards - FILTERED DATA
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Today\'s Sales',
                          _todaysSales(filteredOrders),  // ✅ Filtered data
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Pending',
                          _pendingAmount(filteredOrders),  // ✅ Filtered data
                          Icons.access_time,
                          Colors.orange,
                        ),
                      ),
                      if (!isMobile) ...[
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Failed',
                            _failedAmount(filteredOrders),  // ✅ Filtered data
                            Icons.error,
                            Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isMobile ? 20 : 24),

                    // ✅ SAME Charts Layout - BLoC DATA
                    isMobile
                        ? Column(
                            children: [
                              _buildChartColumn(
                                _WeeklyVolumeBarChart(screenWidth, filteredOrders),
                                _RevenueLineChart(screenWidth, filteredOrders),
                              ),
                              SizedBox(height: 20),
                              _buildChartColumn(
                                _SuccessRatePieChart(screenWidth, filteredOrders),
                                _StatusDistributionBarChart(
                                  screenWidth,
                                  filteredOrders,
                                ),
                              ),
                              SizedBox(height: 20),
                              _buildChartColumn(
                                _DailyTrendLineChart(screenWidth, filteredOrders),
                                null
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              // _buildChartRow(
                              //   _WeeklyVolumeBarChart(screenWidth, filteredOrders),
                              //   _RevenueLineChart(screenWidth, filteredOrders),
                              //   'Weekly Volume',
                              // ),
                              // _buildChartRowToggle(_buildWeeklyChart(screenWidth, filteredOrders),'Weekly Volume', _weeklyType, (newType) {
                              //   WidgetsBinding.instance.addPostFrameCallback((_) {
                              //     if (mounted) {
                              //       setState(() => _weeklyType = newType);
                              //       }
                              //     });
                              //   },),

                              // WeeklyVolumeChart(chartName: 'Weekly Volume', currentType: _weeklyType, onToggle: (newType) {
                              //   WidgetsBinding.instance.addPostFrameCallback((_) {
                              //     if(mounted){
                              //       setState( () => _weeklyType = newType);
                              //     }
                              //   });
                              // },
                              // child: _buildWeeklyChart(screenWidth, filteredOrders),),
                              // SizedBox(height: 30),
                              // _buildChartRow(
                              //   _SuccessRatePieChart(screenWidth, filteredOrders),
                              //   // _PaymentMethodPieChart(screenWidth),
                              //   _StatusDistributionBarChart(
                              //     screenWidth,
                              //     filteredOrders,
                              //   ),
                              //   'Status Distribution',
                              // ),
                              SizedBox(height: 30),
                              _buildChartRow(
                                _DailyTrendLineChart(screenWidth, filteredOrders),
                               null,
                               'Daily Transactions',
                              ),
                            ],
                          ),

                    SizedBox(height: isMobile ? 20 : 24),

                ],
              ),
            ),
            // ✅ SAME Play/Pause Button
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: _toggleAnimation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPlaying ? Colors.red.shade400 : Colors.blue.shade400,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

  // ✅ SAME Animation Methods - UNCHANGED
  void _toggleAnimation() async {
   
   
    setState(() => isPlaying = !isPlaying);
   
    if (isPlaying) {
      _resetAnimations();
      await Future.delayed(const Duration(milliseconds: 100));
     
      _startAllAnimations();
    } else {
      _resetAnimations();
    }
  }

  void _resetAnimations() {
    setState(() {
      weeklyVolumeHeights.clear();
      statusHeights.clear();
      revenuePoints.clear();
      dailyPoints.clear();
      weeklyAnimComplete = statusAnimComplete = revenueAnimComplete = dailyAnimComplete = false;
      touchedWeeklyBarIndex = touchedStatusBarIndex = touchedSuccessIndex = touchedPaymentIndex = -1;
    });
  }

  void _startAllAnimations() {
    _startWeeklyVolumeAnimation(context.read<OrdersBloc>().state);
    _startStatusDistributionAnimation(context.read<OrdersBloc>().state);
    _startRevenueAnimation(context.read<OrdersBloc>().state);
    _startDailyAnimation(context.read<OrdersBloc>().state);

    _dailyController.forward(from: 0.0);
  }


bool _allAnimationsComplete () {

  
  
  return weeklyAnimComplete &&
   statusAnimComplete &&
   revenueAnimComplete &&
   dailyAnimComplete;
}

void _checkAllAnimationsComplete() {
  if(_allAnimationsComplete()){
    setState(() {
      isPlaying = false;

      if(_weeklyType == ChartType.line){
        _weeklyType = ChartType.bar;
      }else{
        _weeklyType = ChartType.line;
      }
      
      
    });
  }
}
  // ✅ BLoC DATA PROCESSING - REPLACES JSON LOGIC
  Map<String, Map<String, int>> _processDailyData(
    List<TransactionEntity> orders,
  ) {
    final dailyData = <String, Map<String, int>>{};

    for (final tx in orders) {
      final dateStr =
          "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}";

      dailyData.putIfAbsent(
        dateStr,
        () => {'success': 0, 'pending': 0, 'failed': 0, 'total': 0},
      );

      final amountInPaise = (tx.amount * 100).round();

      // ✅ SAFEST: Use update method
      dailyData.update(dateStr, (value) {
        value['total'] = (value['total'] ?? 0) + amountInPaise;
        return value;
      });

      // ✅ Status updates
      dailyData.update(dateStr, (value) {
        switch (tx.status) {
          case TransactionStatus.success:
            value['success'] = (value['success'] ?? 0) + 1;
            break;
          case TransactionStatus.pending:
            value['pending'] = (value['pending'] ?? 0) + 1;
            break;
          case TransactionStatus.failed:
            value['failed'] = (value['failed'] ?? 0) + 1;
            break;
        }
        return value;
      });
    }

    return dailyData;
  }

  List<String> _getDateKeys(List<TransactionEntity> orders) {
    final dailyData = _processDailyData(orders);
    return dailyData.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
  }

  String _todaysSales(List<TransactionEntity> orders) {
    final todayStr =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
    final todayData = _processDailyData(orders)[todayStr]?['total'] ?? 0;
    return '₹${formatVolume(todayData as double)}';
  }

  String _pendingAmount(List<TransactionEntity> orders) {
    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    ); // Today at 00:00:00 [web:15]

    final totalPending = orders
        .where((tx) {
          if (tx.status != TransactionStatus.pending) return false;

          // ✅ Check if tx.date is today (ignores time, matches your daily grouping)[cite:3]
          final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
          return txDay == today;
        })
        .fold<int>(0, (sum, tx) => sum + (tx.amount * 100).round());

    return '₹${formatVolume(totalPending as double)}';
  }

  String _failedAmount(List<TransactionEntity> orders) {
    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    ); // Today at 00:00:00 [web:15]

    final totalFailed = orders
        .where((tx) {
          if (tx.status != TransactionStatus.failed) return false;

          // ✅ Check if tx.date is today (ignores time, matches your daily grouping)[cite:3]
          final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
          return txDay == today;
        })
        .fold<int>(0, (sum, tx) => sum + (tx.amount * 100).round());

    return '₹${formatVolume(totalFailed as double)}';
  }

  List<double> _weeklyVolumeData(List<TransactionEntity> orders) {
    final dateKeys = _getDateKeys(orders);
    final dailyData = _processDailyData(orders);
    if (dateKeys.isEmpty) return [];
    return dateKeys
        .map(
          (date) => (dailyData[date]?['total'] as int? ?? 0) / 100.toDouble(),
        )
        .toList();
  }

  List<double> _statusDistribution(List<TransactionEntity> orders) {
    if (orders.isEmpty) return [];
    final totalTx = orders.length;
    final successCount = orders
        .where((tx) => tx.status == TransactionStatus.success)
        .length;
    final pendingCount = orders
        .where((tx) => tx.status == TransactionStatus.pending)
        .length;
    final failedCount = orders
        .where((tx) => tx.status == TransactionStatus.failed)
        .length;
    return [
      (successCount / totalTx * 100).clamp(0.0, 100.0),
      (pendingCount / totalTx * 100).clamp(0.0, 100.0),
      (failedCount / totalTx * 100).clamp(0.0, 100.0),
    ];
  }

  List<FlSpot> _revenueTrendData(List<TransactionEntity> orders) {
    final dateKeys = _getDateKeys(orders);
    final dailyData = _processDailyData(orders);
    if (dateKeys.isEmpty) {
      return [];
    }
    return dateKeys.asMap().entries.map((entry) {
      final dayIndex = entry.key;
      final date = entry.value;
      final total = dailyData[date]?['total'] as int? ?? 0;
      return FlSpot(dayIndex.toDouble(), total.toDouble() / 100);
    }).toList();
  }

  List<FlSpot> _dailyTransactionTrend(List<TransactionEntity> orders) {
    final dateKeys = _getDateKeys(orders);
    final dailyData = _processDailyData(orders);
    if (dateKeys.isEmpty) {
      return [];
    }
    return dateKeys.asMap().entries.map((entry) {
      final dayIndex = entry.key;
      final date = entry.value;
      final success = dailyData[date]?['success'] as int? ?? 0;
      final pending = dailyData[date]?['pending'] as int? ?? 0;
      final failed = dailyData[date]?['failed'] as int? ?? 0;
      final totalTx = (success + pending + failed).clamp(1, 15);
      return FlSpot(dayIndex.toDouble(), totalTx.toDouble());
    }).toList();
  }

  String get dateRange {
    final orders = context.read<OrdersBloc>().state is OrdersPaginationLoaded
        ? (context.read<OrdersBloc>().state as OrdersPaginationLoaded).orders
        : <TransactionEntity>[];
    final dateKeys = _getDateKeys(orders);
    if (dateKeys.isEmpty) return getLast15DaysRange();
    final start = DateTime.parse(dateKeys.first);
    final end = DateTime.parse(dateKeys.last);
    return '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd').format(end)}, 2026';
  }

   String _getDateLabel(int index) {
    final orders = context.read<OrdersBloc>().state is OrdersPaginationLoaded
        ? (context.read<OrdersBloc>().state as OrdersPaginationLoaded).orders
        : <TransactionEntity>[];
    final dateKeys = _getDateKeys(orders);
  if (index >= 0 && index < dateKeys.length) {
    final date = DateTime.parse(dateKeys[index]);
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthName = monthNames[date.month - 1];
    return '${date.day} $monthName';
  }
  return '';
}
String getLast15DaysRange() {
  final now = DateTime.now();
  final endDate = DateTime(now.year, now.month, now.day);  // Today
  final startDate = endDate.subtract(Duration(days: 14));  // 15 days total
  
  final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  
  final startLabel = '${startDate.day} ${monthNames[startDate.month - 1]}';
  final endLabel = '${endDate.day} ${monthNames[endDate.month - 1]}';
  
  return '$startLabel - $endLabel, ${now.year}';
}

  double _getChartHeight(double screenWidth) =>
      screenWidth <= 800 ? 280.0 : 320.0;

  // ✅ SAME Animation methods - pass BLoC state
  void _startWeeklyVolumeAnimation(OrdersState state) {
    final orders = state is OrdersPaginationLoaded
        ? state.orders
        : <TransactionEntity>[];
    weeklyVolumeHeights.clear();
    final targetData = _weeklyVolumeData(orders);
    for (int i = 0; i < targetData.length; i++) {
    _weeklyVolumeTimer = Timer(Duration(milliseconds: 60 * i), () {
        if (mounted) {
          setState(() {
            final normalizedHeight =
                (targetData[i] / (targetData.reduce(math.max) * 1.1)) * 200;
            weeklyVolumeHeights.add(normalizedHeight);
            if (i == targetData.length - 1){ weeklyAnimComplete = true;
            _checkAllAnimationsComplete();
            }
          });
        }
      });
    }
  }

  void _startStatusDistributionAnimation(OrdersState state) {
    final orders = state is OrdersPaginationLoaded
        ? state.orders
        : <TransactionEntity>[];
    statusHeights.clear();
    final targetData = _statusDistribution(orders);
    for (int i = 0; i < targetData.length; i++) {
    _statusTimer = Timer(Duration(milliseconds: 80 * i), () {
        if (mounted) {
          setState(() {
            statusHeights.add(targetData[i] * 2.5);
            if (i == targetData.length - 1) {statusAnimComplete = true;
            _checkAllAnimationsComplete();}
          });
        }
      });
    }
  }

  void _startRevenueAnimation(OrdersState state) {
    final orders = state is OrdersPaginationLoaded
        ? state.orders
        : <TransactionEntity>[];
    final targetPoints = _revenueTrendData(orders);
    _revenueTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (revenuePoints.length >= targetPoints.length) {
        revenuePoints = List.from(targetPoints);
        revenueAnimComplete = true;
        _checkAllAnimationsComplete();
        setState(() {});
        timer.cancel();
        return;
      }
      setState(() => revenuePoints.add(targetPoints[revenuePoints.length]));
    });
  }

  void _startDailyAnimation(OrdersState state) {
    print("Staterd DAILY animation");
    final orders = state is OrdersPaginationLoaded
        ? state.orders
        : <TransactionEntity>[];
    final targetPoints = _dailyTransactionTrend(orders);


   final _dailyTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (dailyPoints.length >= targetPoints.length) {
        dailyPoints = List.from(targetPoints);
        dailyAnimComplete = true;
        _checkAllAnimationsComplete();
        setState(() {});
        timer.cancel();
        return;
      }
      setState(() => dailyPoints.add(targetPoints[dailyPoints.length]));
    });

   // _dailyTimer = _newdailyTimer;
   // allDailyTimers.add(_newdailyTimer);

    // print("All Daily Timer Instances ${allDailyTimers.length} ===");
    // for(int i = 0; i < allDailyTimers.length; i++){
    //     final t = allDailyTimers[i];
    //     print('Timer $i: hashCode ${t.hashCode},'
    //            'tick = ${t.tick}, '
    //            'isActive = ${t.isActive}, ' );
    // }

  }

  // ✅ ALL SAME UI METHODS - JUST PASS ORDERS
  Widget _buildActionButtons(bool isMobile) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Onboard',
              Icons.add_business,
              '/onboarding',
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              'Transactions',
              Icons.receipt_long,
              '/transactions',
            ),
          ),
          if (!isMobile) ...[
            SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Reports',
                Icons.description,
                '/reports1',
              ),
            ),
          ],
        ],
      ),
      if (isMobile) ...[
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Reports',
                Icons.description,
                '/reports1',
              ),
            ),
          ],
        ),
      ],
    ],
  );

  Widget _buildActionButton(String label, IconData icon, String route) =>
      ElevatedButton.icon(
        onPressed: () => context.push(route),
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 2,
        ),
      );

  Widget _buildChartRow(Widget leftChart, Widget? rightChart, String chartName) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 25,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          chartName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [

            if (leftChart != null) ...[
              Expanded(child: leftChart),
              if (rightChart != null) ...[ const SizedBox(width: 36), Expanded(child: rightChart),],
            ],

          ],
        ),
      ],
    ),
  );


// Widget _buildChartRowToggle(Widget weeklyChart, String chartName, int currentType, Function(int) onToggle) => Container(
//     padding: const EdgeInsets.all(24),
//     decoration: BoxDecoration(
//       color: Theme.of(context).cardColor,
//       borderRadius: BorderRadius.circular(20),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(0.1),
//           blurRadius: 25,
//           offset: const Offset(0, 8),
//         ),
//       ],
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//           Text(
//           chartName,
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w700,
//             color: Theme.of(context).textTheme.titleLarge?.color,
//           ),
//         ),
//         IconButton(onPressed: () => onToggle (1 - currentType),
//          icon: Icon(currentType == 0 ? Icons.show_chart : Icons.bar_chart,
//          size: 28,
//          color: Theme.of(context).textTheme.titleLarge?.color,),
//          tooltip: currentType == 0 ? 'Switch to Line chart' : 'Switch to Bar chart',
//          style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5)),
//          padding: const EdgeInsets.all(8),
//          )
//           ],
//         ),
        
//         const SizedBox(height: 24),
//       //  Expanded(child: weeklyChart),
//          SizedBox(
//         height: 300,  // Fixed height for charts
//         child: weeklyChart,
//       ),
//       ],
//     ),
//   );
  
  Widget _buildChartColumn(Widget chart1, Widget? chart2) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 25,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Charts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 20),
        if (chart1 != null) ...[
          chart1,
          if (chart2 != null) ...[const SizedBox(height: 20), chart2],
        ],
      ],
    ),
  );

  BarChartGroupData _makeGroupData(int x, double y, Color color) =>
      BarChartGroupData(
        x: x,
        barRods: [
          BarChartRodData(
            toY: y.clamp(0.0, double.infinity),
            color: color,
            width: 20,
            borderRadius: BorderRadius.circular(6),
             backDrawRodData: null,
          ),
        ],
      );

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).dividerColor),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    ),
  );

Widget _buildWeeklyChart(double screenWidth,
    List<TransactionEntity> orders) {
  return _weeklyType == ChartType.bar 
    ? _WeeklyVolumeBarChart(screenWidth, orders)    // Shows BAR chart
    : _RevenueLineChart( screenWidth, orders);  // Shows LINE chart
}

  // ✅ SAME CHART WIDGETS - NOW TAKE ORDERS PARAMETER
  Widget _WeeklyVolumeBarChart(
    double screenWidth,
    List<TransactionEntity> orders,
  ) {
    final amounts = _weeklyVolumeData(orders);
    final maxAmount = amounts.isNotEmpty
        ? amounts.reduce(math.max) * 1.1
        : 500000.0;
    final dateKeys = _getDateKeys(orders);

    // final barGroups = List.generate(amounts.length, (index) {
    //   final animatedHeight = amounts[index];
    //   return _makeGroupData(index, animatedHeight, Colors.blue.shade600);
    // });

    return Container(
      height: _getChartHeight(screenWidth),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          SizedBox(height: 16),
          Expanded(
            child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0), 
                duration: const Duration(milliseconds: 3000),
                curve: Curves.easeOutBack,
                builder: (context, progress, child) {
                      final barGroups = List.generate(amounts.length, (index) {
                      final animatedHeight = amounts[index] * progress;
                      return _makeGroupData(index, animatedHeight, Colors.blue.shade600);
                     });
               
            return BarChart(
              BarChartData(
                maxY: maxAmount,
                minY: 0,
                barGroups: barGroups,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text("Date"),
                    axisNameSize: 15,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dateKeys.length)
                          return SizedBox.shrink();
                        final day = dateKeys[index].substring(8, 10);
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            _getDateLabel(index),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text("Amount (₹)"),
                    axisNameSize: 15,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval: maxAmount / 5,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text(
                          '  ${formatVolume(value)}',
                          style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ),
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
              );
            },
            ),
          ),
        ],
      ),
    );
  }

  Widget _RevenueLineChart(double screenWidth, List<TransactionEntity> orders) {
    final spots = revenuePoints.isNotEmpty ? revenuePoints : _revenueTrendData(orders);
    final maxAmount = spots.isNotEmpty ? spots.map((e) => e.y).reduce(math.max) * 1.1 : 500000.0;
    final dateKeys = _getDateKeys(orders);

    return Container(
      height: _getChartHeight(screenWidth),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          SizedBox(height: 16),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 2400),
              curve: Curves.easeOutBack, 
              builder: (context, progress, child) {
                final maxVisibleIndex = (dateKeys.length * progress).floor();
                  final visibleSpots = spots.asMap().entries.where((entry) => entry.key <= maxVisibleIndex)
                        .map((entry)=> FlSpot(entry.value.x, entry.value.y)).toList();
              return  LineChart(
              LineChartData(
                minX: 0,
                maxX: (dateKeys.length - 1).toDouble(),
                maxY: maxAmount,
                minY: 0,
                gridData: FlGridData(show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1),),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text("Date"),
                    axisNameSize: 15,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dateKeys.length){
                          return SizedBox.shrink();
                        }
                        final day = dateKeys[index].substring(8, 10);
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                             _getDateLabel(index),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text("Amount (₹)"),
                    axisNameSize: 15,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval: maxAmount / 5,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text(
                          '  ${formatVolume(value)}',
                          style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color,),
                        ),
                      ),
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: visibleSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    preventCurveOverShooting: true,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                    ),
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
              }
            ),
          ),
        ],
      ),
    );
  }

  // ✅ BLoC VERSIONS - Pass `List<TransactionEntity> orders` parameter

  Widget _DailyTrendLineChart(
    double screenWidth,
    List<TransactionEntity> orders,
  ) {
    final spots = dailyPoints.isNotEmpty
        ? dailyPoints
        : _dailyTransactionTrend(orders);
    final maxCount = spots.isNotEmpty
        ? spots.map((e) => e.y).reduce(math.max).ceil() * 1.1
        : 15.0;
    final dateKeys = _getDateKeys(orders);

    return Container(
      height: _getChartHeight(screenWidth),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          SizedBox(height: 16),
          Expanded( 
            child: AnimatedBuilder(  // ✅ REPLACES TweenAnimationBuilder
               animation: _dailyAnimation,
                builder: (context, child){
                     final progress = _dailyAnimation.value;  // ✅ Single source
              final maxVisibleIndex = (dateKeys.length * progress).floor();
              final visibleSpots = spots.asMap().entries
                  .where((entry) => entry.key <= maxVisibleIndex)
                  .map((entry) => FlSpot(entry.value.x, entry.value.y))
                  .toList();
                return LineChart(
              LineChartData(
                minX: 0,
                maxX: (dateKeys.length - 1).toDouble(),
                maxY: maxCount,
                minY: 0,
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text("Date"),
                    axisNameSize: 15,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dateKeys.length)
                          return SizedBox.shrink();
                        final day = dateKeys[index].substring(8, 10);
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                             _getDateLabel(index),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text("Transactions"),
                    axisNameSize: 15,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: (maxCount / 5),
                      getTitlesWidget: (value, meta) {
                        final count = value.toInt();
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Text(
                            '  $count',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: visibleSpots,
                    isCurved: true,
                    preventCurveOverShooting:true,
                    color: Colors.purple.shade600,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.purple.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
             );
             },
            ),
            
          ),
        ],
      ),
    );
  }


  Widget _StatusDistributionBarChart(
    double screenWidth,
    List<TransactionEntity> orders,
  ) {
    final colors = [
      Colors.green.shade700,
      Colors.orange.shade700,
      Colors.red.shade700,
    ];
    final statusLabels = ['Success', 'Pending', 'Failed'];
    final statusDistributionData = _statusDistribution(orders);

    final barGroups = List.generate(
      statusDistributionData.length,
      (index) => _makeGroupData(
        index,
        statusHeights.length > index
            ? statusHeights[index]
            : statusDistributionData[index],
        colors[index],
      ),
    );

    return Container(
      height: _getChartHeight(screenWidth),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.topRight,
            child: Text(
              _dateRange(orders),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (response?.spot == null) {
                      setState(() => touchedStatusBarIndex = -1);
                      return;
                    }
                    setState(
                      () => touchedStatusBarIndex =
                          response!.spot!.touchedBarGroupIndex,
                    );
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) =>
                        colors[group.x.clamp(0, 2).toInt()],
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final value =
                          statusDistributionData[groupIndex.clamp(
                            0,
                            statusDistributionData.length - 1,
                          )];
                      return BarTooltipItem(
                        '${statusLabels[groupIndex]}\n${value.round()}%',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateRange(List<TransactionEntity> orders) {
    final dateKeys = _getDateKeys(orders);
    if (dateKeys.isEmpty) return getLast15DaysRange();
    final start = DateTime.parse(dateKeys.first);
    final end = DateTime.parse(dateKeys.last);
    return '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd').format(end)}, 2026';
  }

  Widget _SuccessRatePieChart(
    double screenWidth,
    List<TransactionEntity> orders,
  ) {
    final totalTx = orders.length.clamp(1, 1000);
    final successCount = orders
        .where((tx) => tx.status == TransactionStatus.success)
        .length;
    final pendingCount = orders
        .where((tx) => tx.status == TransactionStatus.pending)
        .length;
    final failedCount = orders
        .where((tx) => tx.status == TransactionStatus.failed)
        .length;

    return Container(
      height: _getChartHeight(screenWidth),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          // const Text(
          //   'Success Rate',
          //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          // ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.topRight,
            child: Text(
              _dateRange(orders),
              style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedSuccessIndex = -1;
                        return;
                      }
                      touchedSuccessIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: successCount.toDouble(),
                    title: '${((successCount / totalTx) * 100).round()}%',
                    radius: touchedSuccessIndex == 0 ? 85.0 : 75.0,
                    titleStyle: TextStyle(
                      fontSize: touchedSuccessIndex == 0 ? 20.0 : 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: pendingCount.toDouble(),
                    title: '${((pendingCount / totalTx) * 100).round()}%',
                    radius: touchedSuccessIndex == 1 ? 85.0 : 75.0,
                    titleStyle: TextStyle(
                      fontSize: touchedSuccessIndex == 1 ? 20.0 : 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.red,
                    value: failedCount.toDouble(),
                    title: '${((failedCount / totalTx) * 100).round()}%',
                    radius: touchedSuccessIndex == 2 ? 85.0 : 75.0,
                    titleStyle: TextStyle(
                      fontSize: touchedSuccessIndex == 2 ? 20.0 : 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _PaymentMethodPieChart(double screenWidth) {
    return Container(
      height: _getChartHeight(screenWidth),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          const Text(
            'Payment Methods',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.topRight,
            child: Text(
             "",
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedPaymentIndex = -1;
                        return;
                      }
                      touchedPaymentIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: _paymentMethodSections(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _paymentMethodSections() => List.generate(4, (i) {
    final isTouchedItem = i == touchedPaymentIndex;
    final fontSize = isTouchedItem ? 18.0 : 14.0;
    final radius = isTouchedItem ? 85.0 : 75.0;
    return switch (i) {
      0 => PieChartSectionData(
        color: Colors.blue,
        value: 45,
        title: 'UPI',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      1 => PieChartSectionData(
        color: Colors.green,
        value: 30,
        title: 'Card',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      2 => PieChartSectionData(
        color: Colors.purple,
        value: 18,
        title: 'Netbank',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      3 => PieChartSectionData(
        color: Colors.orange,
        value: 7,
        title: 'Wallet',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      _ => throw StateError('Invalid'),
    };
  });
}
