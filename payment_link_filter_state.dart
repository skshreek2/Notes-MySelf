class PaymentLinkFilterState {
  final String status;
  final String dateRange;
  // final String fromDate;
  // final String toDate;

  const PaymentLinkFilterState({
    required this.status,
    required this.dateRange,
    // required this.fromDate,
    // required this.toDate,
  });

  PaymentLinkFilterState copyWith({
    String? status,
    String? dateRange,
    String? fromDate,
    String? toDate,
  }) {
    return PaymentLinkFilterState(
      status: status ?? this.status,
      dateRange: dateRange ?? this.dateRange,
      // fromDate: fromDate ?? this.fromDate,
      // toDate: toDate ?? this.toDate,
    );
  }
}
