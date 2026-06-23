// payment_analytics_state.dart
import 'package:hdfc_merchant_app/features/dashboard_amps/data/payment_response_model.dart';

abstract class PaymentAnalyticsState {}

class PaymentAnalyticsInitial extends PaymentAnalyticsState {}

class PaymentAnalyticsLoading extends PaymentAnalyticsState {}

class PaymentAnalyticsLoaded extends PaymentAnalyticsState {
  final PaymentAnalyticsResponseModel data;

  PaymentAnalyticsLoaded(this.data);
}

class PaymentAnalyticsError extends PaymentAnalyticsState {
  final String message;

  PaymentAnalyticsError(this.message);
}
