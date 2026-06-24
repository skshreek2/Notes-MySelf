import 'package:equatable/equatable.dart';
import 'package:hdfc_merchant_app/features/reports_amps/data/reports_model.dart';

abstract class ReportHistoryState extends Equatable {
  const ReportHistoryState();

  @override
  List<Object?> get props => [];
}

class ReportHistoryInitial extends ReportHistoryState {
  const ReportHistoryInitial();
}

class ReportHistoryLoading extends ReportHistoryState {
  const ReportHistoryLoading();
}

class ReportHistoryPaginationLoaded extends ReportHistoryState {
  final List<ReportEntity> reports;
  // final ReportMetaInfo metaInfo;
  final int currentPage;
  final int totalPages;
  final int rowsPerPage;
  final bool hasReachedMax;
  final String daysFilter;
  final String statusFilter;
  final String totalElements;

  const ReportHistoryPaginationLoaded({
    required this.reports,
    // required this.metaInfo,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.hasReachedMax,
    required this.totalElements,
    this.daysFilter = 'Today',
    this.statusFilter = 'All Status',
  });

  bool get isFirstPage => currentPage == 0;

  ReportHistoryPaginationLoaded copyWith({
    List<ReportEntity>? reports,
    int? currentPage,
    int? totalPages,
    int? rowsPerPage,
    bool? hasReachedMax,
    String? daysFilter,
    String? statusFilter,
    String? totalElements,
  }) {
    return ReportHistoryPaginationLoaded(
      reports: reports ?? this.reports,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      daysFilter: daysFilter ?? this.daysFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      totalElements: totalElements ?? this.totalElements,
    );
  }

  @override
  List<Object?> get props => [
    reports,
    // metaInfo,
    currentPage,
    totalPages,
    rowsPerPage,
    hasReachedMax,
    daysFilter,
    statusFilter,
  ];
}

class GenerateReportLoading extends ReportHistoryState {
  const GenerateReportLoading();
}

class GenerateReportLoaded extends ReportHistoryState {
  const GenerateReportLoaded();
}

class DownloadReportLoading extends ReportHistoryState {
  final String reportId;
  final ReportHistoryPaginationLoaded prevreportState;
  const DownloadReportLoading({
    required this.reportId,
    required this.prevreportState,
  });
}

class DownloadReportLoaded extends ReportHistoryState {
  final String reportId;
  final ReportHistoryPaginationLoaded prevreportState;
  const DownloadReportLoaded({
    required this.reportId,
    required this.prevreportState,
  });
}

class DownloadReportFailure extends ReportHistoryState {
  final String message;
  const DownloadReportFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class GenerateReportFailure extends ReportHistoryState {
  final String message;
  const GenerateReportFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class ReportHistoryFailure extends ReportHistoryState {
  final String message;
  const ReportHistoryFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
