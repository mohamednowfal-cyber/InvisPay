import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:invispay/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KycService {
  final AuthService _auth = AuthService();

  bool get _isConfigured => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db {
    if (!_isConfigured) throw Exception("Firebase not configured");
    return FirebaseFirestore.instance;
  }

  FirebaseStorage get _storage {
    if (!_isConfigured) throw Exception("Firebase not configured");
    return FirebaseStorage.instance;
  }

  String? get _uid => _auth.currentUser?.uid;

  /// Submits KYC details and document to Firebase
  Future<void> submitKyc({
    required String fullName,
    required String idType,
    required String idNumber,
    required File documentFile,
    required String fileExtension,
    File? userPhoto,
    String? photoExtension,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not authenticated');

    if (!_isConfigured) {
      // Mock Submission: Save locally for persistence in demo mode
      await _saveLocalKycData(
        fullName: fullName,
        idType: idType,
        idNumber: idNumber,
        status: 'pending',
        documentUrl: documentFile.path,
        photoUrl: userPhoto?.path,
      );
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    // 1. Upload Document to Storage
    final storagePath =
        'kyc_documents/$uid/id_proof_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final storageRef = _storage.ref().child(storagePath);

    final uploadTask = await storageRef.putFile(documentFile);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    String? photoUrl;
    if (userPhoto != null && photoExtension != null) {
      final photoPath =
          'kyc_photos/$uid/user_photo_${DateTime.now().millisecondsSinceEpoch}.$photoExtension';
      final photoRef = _storage.ref().child(photoPath);
      final photoTask = await photoRef.putFile(userPhoto);
      photoUrl = await photoTask.ref.getDownloadURL();
    }

    // 2. Update Firestore profile and status
    final kycData = {
      'idType': idType,
      'idNumber': idNumber,
      'documentUrl': downloadUrl,
      'photoUrl': photoUrl,
      'submittedAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('users').doc(uid).update({
      'fullName': fullName,
      'kycStatus': 'pending',
      'kycData': kycData,
    });

    // 3. Update local cache
    await _saveLocalKycData(
      fullName: fullName,
      idType: idType,
      idNumber: idNumber,
      status: 'pending',
      documentUrl: downloadUrl,
      photoUrl: photoUrl,
    );
  }

  /// Get current user's KYC status stream
  Stream<Map<String, dynamic>?> get kycStatusStream {
    final uid = _uid;
    if (uid == null) return Stream.empty();

    if (!_isConfigured) {
      // Return a simulated stream using local data for demo persistence
      return _getLocalDataStream();
    }

    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  /// Manually check KYC status
  Future<String> getKycStatus() async {
    final uid = _uid;
    if (uid == null) return 'unknown';

    if (!_isConfigured) return 'not_started'; // Demo default

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return 'pending';

    final data = doc.data();
    final status = data?['kycStatus'] ?? 'pending';

    // Update local cache with latest status from server
    if (data != null) {
      await _saveLocalKycData(
        fullName: data['fullName'] ?? '',
        idType: (data['kycData'] as Map?)?['idType'] ?? '',
        idNumber: (data['kycData'] as Map?)?['idNumber'] ?? '',
        status: status,
      );
    }
    return status;
  }

  // --- Local Persistence Helpers ---

  Future<void> _saveLocalKycData({
    required String fullName,
    required String idType,
    required String idNumber,
    required String status,
    String? documentUrl,
    String? photoUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Merge with existing data to preserve URLs if not provided
    final existingJson = prefs.getString('local_kyc_data');
    Map<String, dynamic>? kycDataMap;
    if (existingJson != null) {
      final existingData = jsonDecode(existingJson) as Map<String, dynamic>;
      kycDataMap = existingData['kycData'] as Map<String, dynamic>?;
    }

    final data = {
      'fullName': fullName,
      'kycStatus': status,
      'kycData': {
        'idType': idType,
        'idNumber': idNumber,
        'documentUrl': documentUrl ?? kycDataMap?['documentUrl'],
        'photoUrl': photoUrl ?? kycDataMap?['photoUrl'],
        'submittedAt':
            kycDataMap?['submittedAt'] ?? DateTime.now().toIso8601String(),
      }
    };
    await prefs.setString('local_kyc_data', jsonEncode(data));
  }

  Stream<Map<String, dynamic>?> _getLocalDataStream() async* {
    final prefs = await SharedPreferences.getInstance();
    while (true) {
      final json = prefs.getString('local_kyc_data');
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>?;
        yield data;
      } else {
        yield null;
      }
      await Future.delayed(
          const Duration(seconds: 5)); // Poll for changes in demo
    }
  }
}
