import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Mock user storage for demo mode
  static User? _mockUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges =>
      isConfigured ? _auth.authStateChanges() : Stream.value(_mockUser);

  bool get isConfigured => Firebase.apps.isNotEmpty;

  // Current User
  User? get currentUser => isConfigured ? _auth.currentUser : _mockUser;

  // Sign Up with Email/Password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (isConfigured) {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } else {
      // Mock mode: Create a demo user
      final mockUid = 'demo_${DateTime.now().millisecondsSinceEpoch}';
      _mockUser = _MockUser(uid: mockUid, email: email);
      return _MockUserCredential(user: _mockUser);
    }
  }

  // Login with Email/Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (isConfigured) {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } else {
      // Mock mode: Return existing mock user or create new one
      if (_mockUser == null || _mockUser!.email != email) {
        final mockUid = 'demo_${DateTime.now().millisecondsSinceEpoch}';
        _mockUser = _MockUser(uid: mockUid, email: email);
      }
      return _MockUserCredential(user: _mockUser);
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    return null;
  }

  // Sign Out
  Future<void> signOut() async {
    if (isConfigured) {
      await _auth.signOut();
    } else {
      _mockUser = null;
    }
  }
}

// Mock User implementation for demo mode
class _MockUser implements User {
  @override
  final String uid;

  @override
  final String? email;

  String? _displayName;

  _MockUser({required this.uid, this.email});

  @override
  String? get displayName => _displayName;

  @override
  Future<void> updateDisplayName(String? displayName) async {
    _displayName = displayName;
  }

  // Implement other required User properties with defaults
  @override
  bool get emailVerified => false;

  @override
  bool get isAnonymous => false;

  @override
  UserMetadata get metadata => _MockUserMetadata();

  @override
  String? get phoneNumber => null;

  @override
  String? get photoURL => null;

  @override
  List<UserInfo> get providerData => [];

  @override
  String? get refreshToken => null;

  @override
  String? get tenantId => null;

  @override
  Future<void> delete() async {}

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async => 'mock_token';

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async =>
      throw UnimplementedError();

  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber,
          [RecaptchaVerifier? verifier]) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithCredential(
          AuthCredential credential) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithProvider(
          AuthProvider provider) async =>
      throw UnimplementedError();

  @override
  Future<void> reload() async {}

  @override
  Future<void> sendEmailVerification(
      [ActionCodeSettings? actionCodeSettings]) async {}

  @override
  Future<User> unlink(String providerId) async => this;

  @override
  Future<void> updatePassword(String newPassword) async {}

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async {}

  @override
  Future<void> updatePhotoURL(String? photoURL) async {}

  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> linkWithRedirect(AuthProvider provider) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) async =>
      throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithRedirect(
          AuthProvider provider) async =>
      throw UnimplementedError();

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    _displayName = displayName;
  }

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail,
      [ActionCodeSettings? actionCodeSettings]) async {}

  @override
  MultiFactor get multiFactor => throw UnimplementedError();
}

class _MockUserMetadata implements UserMetadata {
  @override
  DateTime? get creationTime => DateTime.now();

  @override
  DateTime? get lastSignInTime => DateTime.now();
}

class _MockUserCredential implements UserCredential {
  @override
  final User? user;

  _MockUserCredential({this.user});

  @override
  AdditionalUserInfo? get additionalUserInfo => null;

  @override
  AuthCredential? get credential => null;
}
