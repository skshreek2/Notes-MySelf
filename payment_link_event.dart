import 'package:equatable/equatable.dart';

enum PaymentLinkSearchField { orderId, customerId, createdBy }

abstract class PaymentLinkHistoryEvent extends Equatable {
  const PaymentLinkHistoryEvent();

  @override
  List<Object?> get props => [];
}

class PaymentLinkHistoryFetched extends PaymentLinkHistoryEvent {
  final bool isRefresh;
  const PaymentLinkHistoryFetched({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class PaymentLinkHistoryPageChanged extends PaymentLinkHistoryEvent {
  final int page;
  const PaymentLinkHistoryPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

class PaymentLinkHistoryRowsPerPageChanged extends PaymentLinkHistoryEvent {
  final int rowsPerPage;
  const PaymentLinkHistoryRowsPerPageChanged(this.rowsPerPage);

  @override
  List<Object?> get props => [rowsPerPage];
}

class PaymentLinkHistorySummaryLoaded extends PaymentLinkHistoryEvent {
  const PaymentLinkHistorySummaryLoaded();
}
class PaymentLinkHistorySearchChanged extends PaymentLinkHistoryEvent {
  final String query;
  final PaymentLinkSearchField selectedField;
  const PaymentLinkHistorySearchChanged(this.query, this.selectedField);

  @override
  List<Object?> get props => [query, selectedField];
}

class PaymentLinkHistoryDateRangeChanged extends PaymentLinkHistoryEvent {
  final String fromDate;
  final String toDate;
  final String? timeFrame;
  const PaymentLinkHistoryDateRangeChanged({
    required this.fromDate,
    required this.toDate,
    this.timeFrame,
  });

  @override
  List<Object?> get props => [fromDate, toDate, timeFrame];
}

class PaymentLinkHistoryStatusChanged extends PaymentLinkHistoryEvent {
  final String status;
  const PaymentLinkHistoryStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}
