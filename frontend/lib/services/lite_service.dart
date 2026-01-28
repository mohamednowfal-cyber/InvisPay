import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invispay/models/lite_model.dart';

class LiteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get Lite balance stream
  Stream<double> getLiteBalanceStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return 0.0;
      final data = doc.data() as Map<String, dynamic>;
      return (data['liteBalance'] ?? 0).toDouble();
    });
  }

  // Get Lite transactions stream
  Stream<List<LiteTransaction>> getLiteTransactionsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('liteTransactions')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LiteTransaction.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Add money to Lite wallet
  Future<bool> addMoney(String uid, double amount, String sourceId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(uid);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) throw Exception('User not found');

        final currentBalance = (userDoc.data()?['liteBalance'] ?? 0).toDouble();
        final newBalance = currentBalance + amount;

        // Update balance
        transaction.update(userRef, {'liteBalance': newBalance});

        // Create transaction record
        final txnRef = userRef.collection('liteTransactions').doc();
        transaction.set(txnRef, {
          'type': 'credit',
          'amount': amount,
          'description': 'Added to Lite Wallet',
          'timestamp': FieldValue.serverTimestamp(),
          'sourceId': sourceId,
        });
      });
      return true;
    } catch (e) {
      debugPrint('Error adding money to Lite: $e');
      return false;
    }
  }

  // Withdraw from Lite wallet
  Future<bool> withdraw(String uid, double amount, String destinationId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(uid);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) throw Exception('User not found');

        final currentBalance = (userDoc.data()?['liteBalance'] ?? 0).toDouble();

        if (currentBalance < amount) {
          throw Exception('Insufficient balance');
        }

        final newBalance = currentBalance - amount;

        // Update balance
        transaction.update(userRef, {'liteBalance': newBalance});

        // Create transaction record
        final txnRef = userRef.collection('liteTransactions').doc();
        transaction.set(txnRef, {
          'type': 'transfer',
          'amount': amount,
          'description': 'Withdrawn to Bank',
          'timestamp': FieldValue.serverTimestamp(),
          'destinationId': destinationId,
        });
      });
      return true;
    } catch (e) {
      debugPrint('Error withdrawing from Lite: $e');
      return false;
    }
  }

  // Pay using Lite wallet
  Future<bool> payWithLite(
      String uid, double amount, String description) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(uid);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) throw Exception('User not found');

        final currentBalance = (userDoc.data()?['liteBalance'] ?? 0).toDouble();

        if (currentBalance < amount) {
          throw Exception('Insufficient balance');
        }

        final newBalance = currentBalance - amount;

        // Update balance
        transaction.update(userRef, {'liteBalance': newBalance});

        // Create transaction record
        final txnRef = userRef.collection('liteTransactions').doc();
        transaction.set(txnRef, {
          'type': 'debit',
          'amount': amount,
          'description': description,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (e) {
      debugPrint('Error paying with Lite: $e');
      return false;
    }
  }
}
