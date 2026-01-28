import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseService {
  bool get isConfigured => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db {
    if (!isConfigured) {
      throw Exception("Firebase not configured");
    }
    return FirebaseFirestore.instance;
  }

  // --- Users ---

  Future<void> createUserProfile(User user, {String? mobile}) async {
    if (!isConfigured) return;

    final userRef = _db.collection('users').doc(user.uid);
    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? 'New User',
        'mobile': mobile,
        'photoURL': user.photoURL,
        'kycStatus': 'not_started', // Default for new users
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create Default Accounts
      await _createDefaultAccounts(user.uid);
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    if (!isConfigured) return;
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> _createDefaultAccounts(String uid) async {
    if (!isConfigured) return;
    final userRef = _db.collection('users').doc(uid);
    final accountsRef = userRef.collection('accounts');

    // Fetch user name for holder name
    final userSnap = await userRef.get();
    final name = userSnap.data()?['displayName'] ?? 'InvisPay User';

    // 1. SBI Savings Account
    await accountsRef.add({
      'type': 'Savings Account',
      'number': 'SBI_9012',
      'holderName': name,
      'balance': 125450.00,
      'currency': 'INR',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'bankName': 'State Bank of India',
      'branch': 'Parliament Street, New Delhi',
      'ifsc': 'SBIN0000691',
      'address': 'Parliament House, New Delhi, DL 110001',
    });

    // Set as primary in user profile
    await userRef.update({'primaryAccountId': 'SBI_9012'});

    // 2. InvisPay Wallet
    await accountsRef.add({
      'type': 'Digital Wallet',
      'number': 'INVIS_1098',
      'holderName': name,
      'balance': 12800.00,
      'currency': 'INR',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'bankName': 'InvisPay',
      'branch': 'Main Branch',
      'ifsc': 'INVS0000105',
      'address': 'Software Park, Phase 1, Bengaluru, KA 560100',
    });

    // 3. HDFC Savings Account
    await accountsRef.add({
      'type': 'Savings Account',
      'number': 'HDFC_2345',
      'holderName': name,
      'balance': 500000.00,
      'currency': 'INR',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'bankName': 'HDFC Bank',
      'branch': 'HSR Layout, Bangalore',
      'ifsc': 'HDFC0000456',
      'address': 'Sector 2, HSR Layout, Bengaluru, KA 560102',
    });
  }

  // --- Profile Photo ---

  Future<String?> uploadProfilePhoto(String uid, File file) async {
    if (!isConfigured) return null;
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('profile_photo.jpg');

      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await _db.collection('users').doc(uid).update({
        'photoURL': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  Future<bool> removeProfilePhoto(String uid) async {
    if (!isConfigured) return false;
    try {
      await _db.collection('users').doc(uid).update({
        'photoURL': null,
      });

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('profile_photo.jpg');

      try {
        await storageRef.delete();
      } catch (e) {
        // Ignore if file doesn't exist in storage
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<DocumentSnapshot> getUserStream(String uid) {
    if (!isConfigured) return Stream.empty();
    return _db.collection('users').doc(uid).snapshots();
  }

  Future<DocumentSnapshot?> getUserData(String uid) async {
    if (!isConfigured) return null;
    return await _db.collection('users').doc(uid).get();
  }
  // --- Accounts ---

  Stream<QuerySnapshot> getAccountsStream(String uid) {
    if (!isConfigured) return Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .orderBy('createdAt')
        .snapshots();
  }

  Future<DocumentSnapshot?> getAccountDetails(
      String uid, String accountId) async {
    if (!isConfigured) return null;
    return _db
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .where('number', isEqualTo: accountId)
        .limit(1)
        .get()
        .then((query) => query.docs.isNotEmpty ? query.docs.first : null);
  }

  // --- Transactions ---

  Future<void> createTransaction({
    required String uid,
    required String fromAccountId,
    required String toContact,
    required double amount,
    required String note,
    String type = 'sent',
  }) async {
    if (!isConfigured) return;
    await _db.collection('users').doc(uid).collection('transactions').add({
      'type': type, // sent, received, requested
      'fromAccountId': fromAccountId,
      'toContact': toContact,
      'amount': amount,
      'note': note,
      'status': 'processing',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getTransactionsStream(String uid) {
    if (!isConfigured) return Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getAccountTransactionsStream(
      String uid, String accountId) {
    if (!isConfigured) return Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('fromAccountId', isEqualTo: accountId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> setPrimaryAccount(String uid, String accountId) async {
    if (!isConfigured) return;
    await _db.collection('users').doc(uid).update({
      'primaryAccountId': accountId,
    });
  }
}
