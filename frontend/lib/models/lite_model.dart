import 'package:cloud_firestore/cloud_firestore.dart';

class LiteTransaction {
  final String id;
  final String type; // 'credit', 'debit', 'transfer'
  final double amount;
  final String description;
  final DateTime timestamp;
  final String? sourceId;
  final String? destinationId;

  LiteTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    this.sourceId,
    this.destinationId,
  });

  factory LiteTransaction.fromFirestore(Map<String, dynamic> data, String id) {
    return LiteTransaction(
      id: id,
      type: data['type'] ?? 'debit',
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      sourceId: data['sourceId'],
      destinationId: data['destinationId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'amount': amount,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      if (sourceId != null) 'sourceId': sourceId,
      if (destinationId != null) 'destinationId': destinationId,
    };
  }
}

class LiteWallet {
  final double balance;
  final String status; // 'active', 'low', 'empty'
  final DateTime lastUpdated;

  LiteWallet({
    required this.balance,
    required this.status,
    required this.lastUpdated,
  });

  factory LiteWallet.fromBalance(double balance) {
    String status;
    if (balance == 0) {
      status = 'empty';
    } else if (balance <= 100) {
      status = 'low';
    } else {
      status = 'active';
    }

    return LiteWallet(
      balance: balance,
      status: status,
      lastUpdated: DateTime.now(),
    );
  }
}
