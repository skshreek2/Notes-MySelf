// payment_analytics_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/bloc/payment_analytics_event.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/bloc/payment_analytics_state.dart';
import 'package:hdfc_merchant_app/features/dashboard_amps/data/payment_repository.dart';

class PaymentAnalyticsBloc
    extends Bloc<PaymentAnalyticsEvent, PaymentAnalyticsState> {
  final PaymentAnalyticsRepository repository;

  PaymentAnalyticsBloc(this.repository) : super(PaymentAnalyticsInitial()) {
    on<LoadPaymentAnalytics>(_onLoadPaymentAnalytics);
    on<RefreshPaymentAnalytics>(_onRefreshPaymentAnalytics);
  }

  Future<void> _onLoadPaymentAnalytics(
    LoadPaymentAnalytics event,
    Emitter<PaymentAnalyticsState> emit,
  ) async {
    emit(PaymentAnalyticsLoading());
    try {
      final result = await repository.getPaymentAnalytics(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      emit(PaymentAnalyticsLoaded(result));
    } catch (e) {
      emit(PaymentAnalyticsError(e.toString()));
    }
  }

  Future<void> _onRefreshPaymentAnalytics(
    RefreshPaymentAnalytics event,
    Emitter<PaymentAnalyticsState> emit,
  ) async {
    try {
      final result = await repository.getPaymentAnalytics(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );
      emit(PaymentAnalyticsLoaded(result));
    } catch (e) {
      emit(PaymentAnalyticsError(e.toString()));
    }
  }
}
