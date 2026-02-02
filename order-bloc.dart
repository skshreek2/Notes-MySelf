import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/orders_entity.dart';
import '../data/orders_repository.dart';


part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrdersRepository repository;
  int _currentPage = 1;
  String _currentSearch = ''; // ✅ Store search query

  DateTime? _fromDate;
  DateTime? _toDate;

  OrdersBloc({required this.repository}) : super(const OrdersInitial()) {
    on<OrdersFetched>(_onFetched);
    on<OrdersNextPageRequested>(_onNextPage);
    on<OrdersPreviousPageRequested>(_onPreviousPage);
    on<OrdersFieldFilterApplied>(_onFilterApplied);
    on<OrdersAdvancedFilterApplied>(_onAdvancedFilter);
    on<OrdersSearchChanged>(_onSearchChanged);
    on<OrdersDateRangeChanged>(_onDateRangeChanged);
    
    // Default to last 7 days
    _toDate = DateTime.now();
    _fromDate = _toDate!.subtract(const Duration(days: 15));
  }

  Future<void> _onDateRangeChanged(OrdersDateRangeChanged event, Emitter<OrdersState> emit) async {
    _fromDate = event.fromDate;
    _toDate = event.toDate;
    _currentPage = 1;
    emit(const OrdersLoading());
    try {
      final response = await repository.fetchOrdersPaginated(
        page: 1,
        size: 10,
        search: _currentSearch,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      emit(OrdersPaginationLoaded(
        orders: response.transactions,
        metaInfo: response.metaInfo,
        currentPage: response.currentPage,
        totalPages: response.totalPages,
        hasReachedMax: !response.hasMore,
      ));
    } on Exception catch (e) {
      emit(OrdersFailure(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSearchChanged(OrdersSearchChanged event, Emitter<OrdersState> emit) async {
     _currentSearch = event.query;
     _currentPage = 1; // Reset to page 1
     emit(const OrdersLoading());

       try {
         final response = await repository.fetchOrdersPaginated(
           page: 1,
           size: 10,
           search: _currentSearch,
           fromDate: _fromDate,
           toDate: _toDate,
         );

         emit(OrdersPaginationLoaded(
           orders: response.transactions,
           metaInfo: response.metaInfo,
           currentPage: response.currentPage,
           totalPages: response.totalPages,
           hasReachedMax: !response.hasMore,
         ));
       } on Exception catch (e) {
         emit(OrdersFailure(message: e.toString().replaceAll('Exception: ', '')));
       }

  }

  Future<void> _onFetched(OrdersFetched event, Emitter<OrdersState> emit) async {
    emit(const OrdersLoading());
    try {
      int size = 10;
      if(event.isDashBoard)
          size=200;
      final response = await repository.fetchOrdersPaginated(
        page: 1,
        size: size,
        search: _currentSearch, // ✅ Pass search
        fromDate: _fromDate,
        toDate: _toDate,
      );

      _currentPage = 1;

      emit(OrdersPaginationLoaded(
        orders: response.transactions,
        metaInfo: response.metaInfo,
        currentPage: response.currentPage,
        totalPages: response.totalPages,
        hasReachedMax: !response.hasMore,
      ));
    } catch (e) {
      emit(OrdersFailure(message: e.toString().replaceAll('Exception: ', '')));
    }
  }


  Future<void> _onNextPage(OrdersNextPageRequested event, Emitter<OrdersState> emit) async {
    final currentState = state;
    if (currentState is! OrdersPaginationLoaded || currentState.hasReachedMax) return;

    emit(OrdersPaginationLoading(currentState.orders));

    try {
      final response = await repository.fetchOrdersPaginated(
        page: currentState.currentPage + 1,
        size: 10,
        search: _currentSearch,
        // ✅ Pass search
        fromDate: _fromDate,
        toDate: _toDate,
      );

      emit(OrdersPaginationLoaded(
        orders: response.transactions,
        metaInfo: response.metaInfo,
        currentPage: response.currentPage,
        totalPages: response.totalPages,
        hasReachedMax: !response.hasMore,
      ));
    } catch (e) {
      emit(OrdersFailure(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onPreviousPage(OrdersPreviousPageRequested event, Emitter<OrdersState> emit) async {
    final currentState = state;
    if (currentState is! OrdersPaginationLoaded || currentState.isFirstPage) return;

    emit(OrdersPaginationLoading(currentState.orders));

    try {
      final response = await repository.fetchOrdersPaginated(
        page: currentState.currentPage - 1,
        size: 10,
        search: _currentSearch, // ✅ Pass search
        fromDate: _fromDate,
        toDate: _toDate,
      );

      emit(OrdersPaginationLoaded(
        orders: response.transactions,
        metaInfo: response.metaInfo,
        currentPage: response.currentPage,
        totalPages: response.totalPages,
        hasReachedMax: !response.hasMore,
      ));
    } catch (e) {
      emit(OrdersFailure(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
  Future<void> _onFilterApplied(OrdersFieldFilterApplied event, Emitter<OrdersState> emit) async {
    emit(const OrdersLoading());
    try {
      _currentPage = 1;
      final response = await repository.fetchOrdersPaginated(
        page: 1, 
        size: 10,
        search: _currentSearch,
      );
      emit(OrdersPaginationLoaded(
        orders: response.transactions,
        metaInfo: response.metaInfo,
        currentPage: response.currentPage,
        totalPages: response.totalPages,
        hasReachedMax: !response.hasMore,
      ));
    } catch (e) {
      emit(OrdersFailure(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAdvancedFilter(OrdersAdvancedFilterApplied event, Emitter<OrdersState> emit) async {
    emit(const OrdersLoading());
    try {
      _currentPage = 1;
      final response = await repository.fetchOrdersPaginated(
         page: 1, 
         size: 10,
         search: _currentSearch,
      );
       emit(OrdersPaginationLoaded(
        orders: response.transactions,
        metaInfo: response.metaInfo,
        currentPage: response.currentPage,
        totalPages: response.totalPages,
        hasReachedMax: !response.hasMore,
      ));
    } catch (e) {
      emit(OrdersFailure(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
}
