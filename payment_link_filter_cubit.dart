import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hdfc_merchant_app/features/payment_link/bloc/payment_link_filter_state.dart';

class PaymentLinkFilterCubit extends Cubit<PaymentLinkFilterState> {
  PaymentLinkFilterCubit()
    : super(PaymentLinkFilterState(status: "All Status", dateRange: "Today"));

  void changeStatus(String status) {
    emit(state.copyWith(status: status));
  }

  void changesDateRange(String dateRange) {
    emit(state.copyWith(dateRange: dateRange));
  }
}
