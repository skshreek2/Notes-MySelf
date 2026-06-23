import 'package:bloc/bloc.dart';
import 'package:hdfc_merchant_app/features/payment_link/data/payment_link_model.dart';
import 'package:hdfc_merchant_app/features/payment_link/data/payment_link_repository_copy.dart';
import 'payment_link_history_event.dart';
import 'payment_link_history_state.dart';

class PaymentLinkHistoryBloc
    extends Bloc<PaymentLinkHistoryEvent, PaymentLinkHistoryState> {
  final PaymentLinkRepository repository;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  String _currentSearch = '';
  PaymentLinkSearchField _selectedSearchField = PaymentLinkSearchField.orderId;
  String _selectedStatus = 'All Status';
  String _seletedDateRange = "Today";
  PaymentLinksSummaryPayload? _summary;

  String? _fromDate;
  String? _toDate;

  PaymentLinkHistoryBloc({required this.repository})
    : super(const PaymentLinkHistoryInitial()) {
    on<PaymentLinkHistoryFetched>(_onFetched);
    on<PaymentLinkHistoryPageChanged>(_onPageChanged);
    on<PaymentLinkHistoryRowsPerPageChanged>(_onRowsPerPageChanged);
    on<PaymentLinkHistorySearchChanged>(_onSearchChanged);
    on<PaymentLinkHistoryDateRangeChanged>(_onDateRangeChanged);
    on<PaymentLinkHistoryStatusChanged>(_onStatusChanged);
    on<PaymentLinkHistorySummaryLoaded>(_onSummaryLoaded);
  }

  Future<void> _onFetched(
    PaymentLinkHistoryFetched event,
    Emitter<PaymentLinkHistoryState> emit,
  ) async {
    emit(const PaymentLinkHistoryLoading());
    try {
      if (event.isRefresh) {
        _currentPage = 1;
      }
      final response = await repository.fetchPaymentLinksPaginated(
        page: _currentPage,
        size: _rowsPerPage,
        search: _currentSearch,
        fieldName: _currentSearch.isNotEmpty ? _selectedSearchField.name : null,
        fromDate: _fromDate,
        toDate: _toDate,
        status: _selectedStatus,
      );
      final summary = await repository.fetchPaymentLinksSummary(
        fromDate: _fromDate!,
        toDate: _toDate!,
      );

      emit(
        PaymentLinkHistoryPaginationLoaded(
          paymentLinks: response.paymentLinks,
          totalRecords: response.totalRecords,
          currentPage: response.currentPage,
          totalPages: response.totalPages,
          rowsPerPage: _rowsPerPage,
          hasReachedMax: !response.hasMore,
          summary: summary,
          selectedStatus: _selectedStatus,
          selectedDateRange: _seletedDateRange,
        ),
      );
    } catch (e) {
      emit(
        PaymentLinkHistoryFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onPageChanged(
    PaymentLinkHistoryPageChanged event,
    Emitter<PaymentLinkHistoryState> emit,
  ) async {
    _currentPage = event.page;
    emit(const PaymentLinkHistoryLoading());
    try {
      final response = await repository.fetchPaymentLinksPaginated(
        page: _currentPage,
        size: _rowsPerPage,
        search: _currentSearch,
        fieldName: _currentSearch.isNotEmpty ? _selectedSearchField.name : null,
        fromDate: _fromDate,
        toDate: _toDate,
        status: _selectedStatus,
      );
      final summary = await repository.fetchPaymentLinksSummary(
        fromDate: _fromDate!,
        toDate: _toDate!,
      );

      emit(
        PaymentLinkHistoryPaginationLoaded(
          paymentLinks: response.paymentLinks,
          totalRecords: response.totalRecords,
          currentPage: response.currentPage,
          totalPages: response.totalPages,
          rowsPerPage: _rowsPerPage,
          hasReachedMax: !response.hasMore,
          summary: summary,
          selectedStatus: _selectedStatus,
          selectedDateRange: _seletedDateRange,
        ),
      );
    } catch (e) {
      emit(
        PaymentLinkHistoryFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onRowsPerPageChanged(
    PaymentLinkHistoryRowsPerPageChanged event,
    Emitter<PaymentLinkHistoryState> emit,
  ) async {
    _rowsPerPage = event.rowsPerPage;
    _currentPage = 1;
    emit(const PaymentLinkHistoryLoading());
    try {
      final response = await repository.fetchPaymentLinksPaginated(
        page: _currentPage,
        size: _rowsPerPage,
        search: _currentSearch,
        fieldName: _currentSearch.isNotEmpty ? _selectedSearchField.name : null,
        fromDate: _fromDate,
        toDate: _toDate,
        status: _selectedStatus,
      );
      final summary = await repository.fetchPaymentLinksSummary(
        fromDate: _fromDate!,
        toDate: _toDate!,
      );
      emit(
        PaymentLinkHistoryPaginationLoaded(
          paymentLinks: response.paymentLinks,
          totalRecords: response.totalRecords,
          currentPage: response.currentPage,
          totalPages: response.totalPages,
          rowsPerPage: _rowsPerPage,
          hasReachedMax: !response.hasMore,
          summary: summary,
          selectedStatus: _selectedStatus,
          selectedDateRange: _seletedDateRange,
        ),
      );
    } catch (e) {
      emit(
        PaymentLinkHistoryFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onSearchChanged(
    PaymentLinkHistorySearchChanged event,
    Emitter<PaymentLinkHistoryState> emit,
  ) async {
    _currentSearch = event.query;
    _selectedSearchField = event.selectedField;
    _currentPage = 1;
    emit(const PaymentLinkHistoryLoading());
    try {
      final response = await repository.fetchPaymentLinksPaginated(
        page: _currentPage,
        size: _rowsPerPage,
        search: _currentSearch,
        fieldName: _currentSearch.isNotEmpty ? _selectedSearchField.name : null,
        fromDate: _fromDate,
        toDate: _toDate,
        status: _selectedStatus,
      );

      final summary = await repository.fetchPaymentLinksSummary(
        fromDate: _fromDate!,
        toDate: _toDate!,
      );
      emit(
        PaymentLinkHistoryPaginationLoaded(
          paymentLinks: response.paymentLinks,
          totalRecords: response.totalRecords,
          currentPage: response.currentPage,
          totalPages: response.totalPages,
          rowsPerPage: _rowsPerPage,
          hasReachedMax: !response.hasMore,
          summary: summary,
          selectedStatus: _selectedStatus,
          selectedDateRange: _seletedDateRange,
        ),
      );
    } catch (e) {
      emit(
        PaymentLinkHistoryFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onDateRangeChanged(
    PaymentLinkHistoryDateRangeChanged event,
    Emitter<PaymentLinkHistoryState> emit,
  ) async {
    _fromDate = event.fromDate;
    _toDate = event.toDate;
    _currentPage = 1;
    emit(const PaymentLinkHistoryLoading());
    try {
      final response = await repository.fetchPaymentLinksPaginated(
        page: _currentPage,
        size: _rowsPerPage,
        search: _currentSearch,
        fieldName: _currentSearch.isNotEmpty ? _selectedSearchField.name : null,
        fromDate: _fromDate,
        toDate: _toDate,
        status: _selectedStatus,
      );
      final summary = await repository.fetchPaymentLinksSummary(
        fromDate: _fromDate!,
        toDate: _toDate!,
      );
      emit(
        PaymentLinkHistoryPaginationLoaded(
          paymentLinks: response.paymentLinks,
          totalRecords: response.totalRecords,
          currentPage: response.currentPage,
          totalPages: response.totalPages,
          rowsPerPage: _rowsPerPage,
          hasReachedMax: !response.hasMore,
          summary: summary,
          selectedStatus: _selectedStatus,
          selectedDateRange: _seletedDateRange,
        ),
      );
    } catch (e) {
      emit(
        PaymentLinkHistoryFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onStatusChanged(
    PaymentLinkHistoryStatusChanged event,
    Emitter<PaymentLinkHistoryState> emit,
  ) async {
    _selectedStatus = event.status;
    _currentPage = 1;
    emit(const PaymentLinkHistoryLoading());
    try {
      final response = await repository.fetchPaymentLinksPaginated(
        page: _currentPage,
        size: _rowsPerPage,
        search: _currentSearch,
        fieldName: _currentSearch.isNotEmpty ? _selectedSearchField.name : null,
        fromDate: _fromDate,
        toDate: _toDate,
        status: _selectedStatus,
      );
      final summary = await repository.fetchPaymentLinksSummary(
        fromDate: _fromDate!,
        toDate: _toDate!,
      );
      emit(
        PaymentLinkHistoryPaginationLoaded(
          paymentLinks: response.paymentLinks,
          totalRecords: response.totalRecords,
          currentPage: response.currentPage,
          totalPages: response.totalPages,
          rowsPerPage: _rowsPerPage,
          hasReachedMax: !response.hasMore,
          summary: summary,
          selectedStatus: _selectedStatus,
          selectedDateRange: _seletedDateRange,
        ),
      );
    } catch (e) {
      emit(
        PaymentLinkHistoryFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onSummaryLoaded(
    PaymentLinkHistorySummaryLoaded event,
    Emitter<PaymentLinkHistoryState> emit,
  ) async {
    try {
      final currentState = state as PaymentLinkHistoryPaginationLoaded?;
      final summary = await repository.fetchPaymentLinksSummary(
        fromDate: _fromDate!,
        toDate: _toDate!,
      );

      if (currentState != null) {
        emit(
          PaymentLinkHistoryPaginationLoaded(
            paymentLinks: currentState.paymentLinks,
            totalRecords: currentState.totalRecords,
            currentPage: currentState.currentPage,
            totalPages: currentState.totalPages,
            rowsPerPage: currentState.rowsPerPage,
            hasReachedMax: currentState.hasReachedMax,
            summary: summary,
            selectedStatus: _selectedStatus,
            selectedDateRange: _seletedDateRange,
          ),
        );
      } else {
        // If no pagination state yet, you can emit a separate summary-only state
        // or just wait for the first fetch
      }
    } catch (e) {
      emit(
        PaymentLinkHistoryFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }
}
