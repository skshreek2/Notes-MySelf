import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hdfc_merchant_app/features/reports_amps/data/reports_repository.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportHistoryBloc extends Bloc<ReportHistoryEvent, ReportHistoryState> {
  final ReportsRepository repository;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  String _currentSearch = '';
  String _selectedStatus = 'All Status';

  DateTime? _fromDate;
  DateTime? _toDate;

  ReportHistoryBloc({required this.repository})
    : super(const ReportHistoryInitial()) {
    on<ReportHistoryFetched>(_onFetched);
    on<ReportHistoryPageChanged>(_onPageChanged);
    on<ReportHistoryRowsPerPageChanged>(_onRowsPerPageChanged);
    on<ReportHistorySearchChanged>(_onSearchChanged);
    on<ReportHistoryDateRangeChanged>(_onDateRangeChanged);
    on<ReportHistoryStatusChanged>(_onStatusChanged);
    on<GenerateNewReport>(_onGenerateNewReport);

    // Default to last 30 days
    // _toDate = DateTime.now();
    // _fromDate = _toDate!.subtract(const Duration(days: 30));
  }

  Future<void> _onGenerateNewReport(
    GenerateNewReport event,
    Emitter<ReportHistoryState> emit,
  ) async {
    emit(const ReportHistoryLoading());
    try {
      final response = await repository.generateNewReport(
        event.fromDate,
        event.toDate,
      );
      print("Response Bloc $response");
      if (response.contains("Success")) {
        print("Inside Condtion");
        emit(GenerateReportLoaded());
      } else {
        emit(ReportHistoryFailure(message: 'Failed to Load data'));
      }
    } catch (e) {
      emit(
        ReportHistoryFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onFetched(
    ReportHistoryFetched event,
    Emitter<ReportHistoryState> emit,
  ) async {
    emit(const ReportHistoryLoading());
    try {
      if (event.isRefresh) {
        _currentPage = 0;
      }

      // print("Event fromDate ${event.fromDate} toDate ${event.toDate}");
      final response = await repository.fetchReportsPaginated(
        page: _currentPage,
        size: _rowsPerPage,
        search: _currentSearch,
        fromDate: event.fromDate,
        toDate: event.toDate,
        status: _selectedStatus,
      );
      // print("Response Bloc $response");

      final state = ReportHistoryPaginationLoaded(
        reports: response.reports,
        currentPage: response.page,
        totalPages: response.totalPages,
        rowsPerPage: response.size,
        hasReachedMax: !response.hasMore,
      );
      print("State---> $state");
      emit(state);
    } catch (e) {
      emit(
        ReportHistoryFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onPageChanged(
    ReportHistoryPageChanged event,
    Emitter<ReportHistoryState> emit,
  ) async {
    _currentPage = event.page;
    emit(const ReportHistoryLoading());
    try {
      final response = await repository.fetchReportsPaginated(
        page: _currentPage,
        size: _rowsPerPage,
        search: _currentSearch,
        fromDate: _fromDate.toString(),
        toDate: _toDate.toString(),
        status: _selectedStatus,
      );

      // emit(
      //   ReportHistoryPaginationLoaded(
      //     refunds: response.refunds,
      //     metaInfo: response.metaInfo,
      //     currentPage: response.currentPage,
      //     totalPages: response.totalPages,
      //     rowsPerPage: _rowsPerPage,
      //     hasReachedMax: !response.hasMore,
      //   ),
      // );
    } catch (e) {
      emit(
        ReportHistoryFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onRowsPerPageChanged(
    ReportHistoryRowsPerPageChanged event,
    Emitter<ReportHistoryState> emit,
  ) async {
    _rowsPerPage = event.rowsPerPage;
    _currentPage = 1;
    emit(const ReportHistoryLoading());
    try {
      final response = await repository.fetchReportsPaginated(
        page: _currentPage,
        size: _rowsPerPage,
        search: _currentSearch,
        fromDate: _fromDate.toString(),
        toDate: _toDate.toString(),
        status: _selectedStatus,
      );

      // emit(
      //   ReportHistoryPaginationLoaded(
      //     refunds: response.refunds,
      //     metaInfo: response.metaInfo,
      //     currentPage: response.currentPage,
      //     totalPages: response.totalPages,
      //     rowsPerPage: _rowsPerPage,
      //     hasReachedMax: !response.hasMore,
      //   ),
      // );
    } catch (e) {
      emit(
        ReportHistoryFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onSearchChanged(
    ReportHistorySearchChanged event,
    Emitter<ReportHistoryState> emit,
  ) async {
    _currentSearch = event.query;
    _currentPage = 1;
    emit(const ReportHistoryLoading());
    try {
      final response = await repository.fetchReportsPaginated(
        page: _currentPage,
        size: _rowsPerPage,
        search: _currentSearch,
        fromDate: _fromDate.toString(),
        toDate: _toDate.toString(),
        status: _selectedStatus,
      );

      // emit(
      //   ReportHistoryPaginationLoaded(
      //     refunds: response.refunds,
      //     metaInfo: response.metaInfo,
      //     currentPage: response.currentPage,
      //     totalPages: response.totalPages,
      //     rowsPerPage: _rowsPerPage,
      //     hasReachedMax: !response.hasMore,
      //   ),
      // );
    } catch (e) {
      emit(
        ReportHistoryFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onDateRangeChanged(
    ReportHistoryDateRangeChanged event,
    Emitter<ReportHistoryState> emit,
  ) async {
    _fromDate = event.fromDate;
    _toDate = event.toDate;
    _currentPage = 1;
    emit(const ReportHistoryLoading());
    try {
      final response = await repository.fetchReportsPaginated(
        page: _currentPage,
        size: _rowsPerPage,
        search: _currentSearch,
        fromDate: _fromDate.toString(),
        toDate: _toDate.toString(),
        status: _selectedStatus,
      );

      // emit(
      //   // ReportHistoryPaginationLoaded(
      //   //   refunds: response.refunds,
      //   //   metaInfo: response.metaInfo,
      //   //   currentPage: response.currentPage,
      //   //   totalPages: response.totalPages,
      //   //   rowsPerPage: _rowsPerPage,
      //   //   hasReachedMax: !response.hasMore,
      //   // ),
      // );
    } catch (e) {
      emit(
        ReportHistoryFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onStatusChanged(
    ReportHistoryStatusChanged event,
    Emitter<ReportHistoryState> emit,
  ) async {
    _selectedStatus = event.status;
    _currentPage = 1;
    emit(const ReportHistoryLoading());
    try {
      final response = await repository.fetchReportsPaginated(
        page: _currentPage,
        size: _rowsPerPage,
        search: _currentSearch,
        fromDate: _fromDate.toString(),
        toDate: _toDate.toString(),
        status: _selectedStatus,
      );

      // emit(
      //   ReportHistoryPaginationLoaded(
      //     refunds: response.refunds,
      //     metaInfo: response.metaInfo,
      //     currentPage: response.currentPage,
      //     totalPages: response.totalPages,
      //     rowsPerPage: _rowsPerPage,
      //     hasReachedMax: !response.hasMore,
      //   ),
      // );
    } catch (e) {
      emit(
        ReportHistoryFailure(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }
}
