import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invispay/models/lite_model.dart';
import 'package:invispay/services/lite_service.dart';

// Lite Balance Provider - Optimized for background sync
final liteBalanceProvider = StreamProvider.family<double, String>((ref, uid) {
  return LiteService().getLiteBalanceStream(uid).handleError((error) {
    // Log error but don't break the stream if possible
    // print('Lite Balance Stream Error: $error');
  });
});

// Lite Transactions Provider - Standardized for history reliability
final liteTransactionsProvider =
    StreamProvider.family<List<LiteTransaction>, String>((ref, uid) {
  return LiteService().getLiteTransactionsStream(uid).handleError((error) {
    // print('Lite Transactions Stream Error: $error');
  });
});

// Lite Status Provider (computed from balance)
final liteStatusProvider = Provider.family<String, double>((ref, balance) {
  if (balance == 0) return 'empty';
  if (balance <= 100) return 'low';
  return 'active';
});

// Lite Wallet Provider (combines balance and status)
final liteWalletProvider = Provider.family<LiteWallet, double>((ref, balance) {
  return LiteWallet.fromBalance(balance);
});
