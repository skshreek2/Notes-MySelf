import 'package:equatable/equatable.dart';

abstract class ReportHistoryEvent extends Equatable {
  const ReportHistoryEvent();

  @override
  List<Object?> get props => [];
}

class GenerateNewReport extends ReportHistoryEvent {
  final String fromDate;
  final String toDate;

  const GenerateNewReport({required this.fromDate, required this.toDate});

  @override
  List<Object?> get props => [fromDate, toDate];
}

class DownloadReportEvent extends ReportHistoryEvent {
  final String reportId;
  final String scheduleName;
  const DownloadReportEvent({
    required this.reportId,
    required this.scheduleName,
  });

  @override
  List<Object?> get props => [reportId];
}

class ReportHistoryFetched extends ReportHistoryEvent {
  final bool isRefresh;
  final String fromDate;
  final String toDate;
  // final String filterStatus;

  const ReportHistoryFetched({
    this.isRefresh = false,
    required this.fromDate,
    required this.toDate,
    // required this.filterStatus,
  });

  @override
  List<Object?> get props => [isRefresh];
}

class ReportHistoryPageChanged extends ReportHistoryEvent {
  final int page;
  const ReportHistoryPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

class ReportHistoryRowsPerPageChanged extends ReportHistoryEvent {
  final int rowsPerPage;
  const ReportHistoryRowsPerPageChanged(this.rowsPerPage);

  @override
  List<Object?> get props => [rowsPerPage];
}

class ReportHistorySearchChanged extends ReportHistoryEvent {
  final String query;
  const ReportHistorySearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class ReportHistoryDateRangeChanged extends ReportHistoryEvent {
  final String fromDate;
  final String toDate;
  final String? timeFrame;
  const ReportHistoryDateRangeChanged({
    required this.fromDate,
    required this.toDate,
    this.timeFrame,
  });

  @override
  List<Object?> get props => [fromDate, toDate, timeFrame];
}

class ReportHistoryStatusChanged extends ReportHistoryEvent {
  final String status;
  const ReportHistoryStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}
