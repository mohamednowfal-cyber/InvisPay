import 'package:flutter_riverpod/flutter_riverpod.dart';

class QrAccount {
  final String id;
  final String name;
  final String number;
  final String type; // 'Bank', 'Wallet', 'Card'
  final String? vpa;
  final String vpaSuffix;

  QrAccount({
    required this.id,
    required this.name,
    required this.number,
    required this.type,
    this.vpa,
    this.vpaSuffix = '@invispay',
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QrAccount && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class QrSelectionNotifier extends Notifier<QrAccount?> {
  @override
  QrAccount? build() {
    return null; // Initial state can be null until data is loaded
  }

  void selectAccount(QrAccount account) {
    state = account;
  }
}

final qrSelectionProvider =
    NotifierProvider<QrSelectionNotifier, QrAccount?>(() {
  return QrSelectionNotifier();
});
