import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedPaymentAccountNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() {
    return {
      'type': 'Savings Account',
      'bankName': 'State Bank of India',
      'number': 'DEMO_SBI_9012',
    };
  }

  void setAccount(Map<String, dynamic> account) {
    state = account;
  }
}

final selectedPaymentAccountProvider =
    NotifierProvider<SelectedPaymentAccountNotifier, Map<String, dynamic>>(() {
  return SelectedPaymentAccountNotifier();
});
