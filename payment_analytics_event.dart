// payment_analytics_event.dart
abstract class PaymentAnalyticsEvent {}

class LoadPaymentAnalytics extends PaymentAnalyticsEvent {
  // final String? filter;
  final String? fromDate;
  final String? toDate;
  // final String? merchantId;

  LoadPaymentAnalytics({this.fromDate, this.toDate});
}

class RefreshPaymentAnalytics extends PaymentAnalyticsEvent {
  // final String? filter;
  final String? fromDate;
  final String? toDate;

  RefreshPaymentAnalytics({this.fromDate, this.toDate});
}
