import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/utils/date_range.dart';
import 'package:hdfc_merchant_app/features/reports_amps/data/reports_repository.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportHistoryBloc extends Bloc<ReportHistoryEvent, ReportHistoryState> {
  final ReportsRepository repository;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  String _currentSearch = '';
  String selectedStatus = 'All Status';
  String selectedDaysFilter = 'Today';
  String? downloadReportId;

  String _fromDate = '';
  String _toDate = '';

  ReportHistoryBloc({required this.repository})
    : super(const ReportHistoryInitial()) {
    on<ReportHistoryFetched>(_onFetched);
    on<ReportHistoryPageChanged>(_onPageChanged);
    on<ReportHistoryRowsPerPageChanged>(_onRowsPerPageChanged);
    on<ReportHistorySearchChanged>(_onSearchChanged);
    on<ReportHistoryDateRangeChanged>(_onDateRangeChanged);
    on<ReportHistoryStatusChanged>(_onStatusChanged);
    on<GenerateNewReport>(_onGenerateNewReport);
    on<DownloadReportEvent>(_onDownloadReport);

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

      if (response.contains("success")) {
        emit(GenerateReportLoaded());

        add(
          ReportHistoryFetched(
            fromDate: "",
            toDate: "",
          ),
        );
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

  Future<void> _onDownloadReport(
    DownloadReportEvent event,
    Emitter<ReportHistoryState> emit,
  ) async {
    downloadReportId = event.reportId;

    // emit(state);
    final currentState = state;


    if (currentState is! ReportHistoryPaginationLoaded) return;
    // if (currentState is ReportHistoryPaginationLoaded) {
    emit(
      DownloadReportLoading(
        reportId: event.reportId,
        prevreportState: currentState,
      ),
    );
    // }
    try {
      await repository.downloadReport(event.reportId, event.scheduleName);
      downloadReportId = null;
      emit(
        DownloadReportLoaded(
          reportId: event.reportId,
          prevreportState: currentState,
        ),
      );

      emit(currentState);
      // emit()
    } catch (e) {
      emit(currentState);
      emit(DownloadReportFailure(message: 'Exception'));
    }
  }

  Future<void> _onFetched(
    ReportHistoryFetched event,
    Emitter<ReportHistoryState> emit,
  ) async {
    emit(const ReportHistoryLoading());
    try {
      if (event.isRefresh) {
        _currentPage = 1;
      }

      final response = await repository.fetchReportsPaginated(
        page: _currentPage,
        size: _rowsPerPage,
        search: _currentSearch,
        fromDate: event.fromDate,
        toDate: event.toDate,
        status: selectedStatus,
      );

      final state = ReportHistoryPaginationLoaded(
        reports: response.reports,
        currentPage: response.page,
        totalPages: response.totalPages,
        rowsPerPage: response.size,
        totalElements: response.totalElements.toString(),
        hasReachedMax: !response.hasMore,
        statusFilter: selectedStatus,
        daysFilter: selectedDaysFilter,
      );

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
        fromDate: "",
        toDate: "",
        status: selectedStatus,
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

      emit(
        ReportHistoryPaginationLoaded(
          reports: response.reports,
          currentPage: response.page,
          totalPages: response.totalPages,
          rowsPerPage: response.size,
          hasReachedMax: !response.hasMore,
          statusFilter: selectedStatus,
          daysFilter: selectedDaysFilter,
          totalElements: response.totalElements.toString(),
        ),
      );
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
        fromDate: "",
        toDate: "",
        status: selectedStatus,
      );

      emit(
        ReportHistoryPaginationLoaded(
          reports: response.reports,
          currentPage: response.page,
          totalPages: response.totalPages,
          rowsPerPage: response.size,
          hasReachedMax: !response.hasMore,
          statusFilter: selectedStatus,
          daysFilter: selectedDaysFilter,
          totalElements: response.totalElements.toString(),
        ),
      );
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
        status: selectedStatus,
      );

      final state = ReportHistoryPaginationLoaded(
        reports: response.reports,
        currentPage: response.page,
        totalPages: response.totalPages,
        rowsPerPage: response.size,
        hasReachedMax: !response.hasMore,
        statusFilter: selectedStatus,
        daysFilter: selectedDaysFilter,
        totalElements: response.totalElements.toString(),
      );

      emit(state);
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
    // _fromDate = event.fromDate;
    // _toDate = event.toDate;
    _currentPage = 1;
    selectedDaysFilter = event.timeFrame!;

    emit(const ReportHistoryLoading());
    try {
      // final response = await repository.fetchReportsPaginated(
      //   page: _currentPage,
      //   size: _rowsPerPage,
      //   search: _currentSearch,
      //   fromDate: _fromDate.toString(),
      //   toDate: _toDate.toString(),
      //   status: selectedStatus,
      // );

      final response = await repository.fetchReportsPaginated(
        page: _currentPage,
        size: _rowsPerPage,
        search: _currentSearch,
        fromDate: event.fromDate,
        toDate: event.toDate,
        status: selectedStatus,
      );

      final state = ReportHistoryPaginationLoaded(
        reports: response.reports,
        currentPage: response.page,
        totalPages: response.totalPages,
        rowsPerPage: response.size,
        hasReachedMax: !response.hasMore,
        statusFilter: selectedStatus,
        daysFilter: selectedDaysFilter,
        totalElements: response.totalElements.toString(),
      );

      emit(state);
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
    selectedStatus = event.status;

    _currentPage = 1;
    if (selectedDaysFilter != 'Custom') {
      final dateRange = DateRangeHelper.getDateRange(selectedDaysFilter);
      _fromDate = dateRange.fromDate;
      _toDate = dateRange.toDate;

      emit(const ReportHistoryLoading());
      try {
        final response = await repository.fetchReportsPaginated(
          page: _currentPage,
          size: _rowsPerPage,
          search: _currentSearch,
          fromDate: _fromDate,
          toDate: _toDate,
          status: selectedStatus,
        );

        final state = ReportHistoryPaginationLoaded(
          reports: response.reports,
          currentPage: response.page,
          totalPages: response.totalPages,
          rowsPerPage: response.size,
          hasReachedMax: !response.hasMore,
          statusFilter: selectedStatus,
          daysFilter: selectedDaysFilter,
          totalElements: response.totalElements.toString(),
        );

        emit(state);
      } catch (e) {
        emit(
          ReportHistoryFailure(
            message: e.toString().replaceAll('Exception: ', ''),
          ),
        );
      }
    }
  }
}
