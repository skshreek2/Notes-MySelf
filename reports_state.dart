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

  const ReportHistoryPaginationLoaded({
    required this.reports,
    // required this.metaInfo,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.hasReachedMax,
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
  }) {
    return ReportHistoryPaginationLoaded(
      reports: reports ?? this.reports,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      daysFilter: daysFilter ?? this.daysFilter,
      statusFilter: statusFilter ?? this.statusFilter,
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

class GenerateReportLoaded extends ReportHistoryState {}

class ReportHistoryFailure extends ReportHistoryState {
  final String message;
  const ReportHistoryFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
