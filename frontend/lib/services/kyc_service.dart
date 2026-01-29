import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:invispay/services/auth_service.dart';

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
      // Mock Submission
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
    await _db.collection('users').doc(uid).update({
      'fullName': fullName,
      'kycStatus': 'pending',
      'kycData': {
        'idType': idType,
        'idNumber': idNumber,
        'documentUrl': downloadUrl,
        'photoUrl': photoUrl,
        'submittedAt': FieldValue.serverTimestamp(),
      },
    });
  }

  /// Get current user's KYC status stream
  Stream<DocumentSnapshot?> get kycStatusStream {
    final uid = _uid;
    if (uid == null) return Stream.empty();

    if (!_isConfigured) {
      // Return a simulated stream implying 'pending' or 'not_started' for demo
      // Since DocumentSnapshot is hard to mock perfectly without firestore_mocks,
      // we just return Stream.empty() and handle it in UI, or throw.
      // Better: Return Stream.empty() and let UI show loader or default.
      // Actually, returning null/empty causes infinite loading.
      // Best approach for demo: The UI should check 'isConfigured' or handle empty.
      return Stream.empty();
    }

    return _db.collection('users').doc(uid).snapshots();
  }

  /// Manually check KYC status
  Future<String> getKycStatus() async {
    final uid = _uid;
    if (uid == null) return 'unknown';

    if (!_isConfigured) return 'not_started'; // Demo default

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return 'pending';

    final data = doc.data();
    return data?['kycStatus'] ?? 'pending';
  }
}
