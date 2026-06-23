import 'package:equatable/equatable.dart';
import '../data/payment_link_model.dart';

abstract class PaymentLinkHistoryState extends Equatable {
  const PaymentLinkHistoryState();

  @override
  List<Object?> get props => [];
}

class PaymentLinkHistoryInitial extends PaymentLinkHistoryState {
  const PaymentLinkHistoryInitial();
}

class PaymentLinkHistoryLoading extends PaymentLinkHistoryState {
  const PaymentLinkHistoryLoading();
}

class PaymentLinkHistoryPaginationLoading extends PaymentLinkHistoryState {
  final List<PaymentLinkEntity> paymentLinks;
  const PaymentLinkHistoryPaginationLoading(this.paymentLinks);

  @override
  List<Object?> get props => [paymentLinks];
}

class PaymentLinkHistoryPaginationLoaded extends PaymentLinkHistoryState {
  final List<PaymentLinkEntity> paymentLinks;
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final int rowsPerPage;
  final bool hasReachedMax;
  final PaymentLinksSummaryPayload? summary; // new
  final String selectedStatus;
  final String selectedDateRange;

  const PaymentLinkHistoryPaginationLoaded({
    required this.paymentLinks,
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
    required this.rowsPerPage,
    required this.hasReachedMax,
    this.summary,
    required this.selectedStatus,
    required this.selectedDateRange,
  });

  bool get isFirstPage => currentPage == 0;

  @override
  List<Object?> get props => [
    paymentLinks,
    currentPage,
    totalPages,
    totalRecords,
    rowsPerPage,
    hasReachedMax,
    summary,
    selectedStatus,
    selectedDateRange,
  ];
}

class PaymentLinkHistoryFailure extends PaymentLinkHistoryState {
  final String message;
  const PaymentLinkHistoryFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
