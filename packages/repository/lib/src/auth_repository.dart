import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:models/models.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  /// Register a new user with email + password
  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String? shopName,
    String? shopAddress,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(name);

    final user = UserModel(
      id: cred.user!.uid,
      name: name,
      email: email,
      phone: phone,
      role: role,
      isActive: true,
      isApproved: role == UserRole.customer || role == UserRole.admin,
      createdAt: DateTime.now(),
      shopName: shopName,
      shopAddress: shopAddress,
    );

    await _db.collection('users').doc(user.id).set(user.toFirestore());
    return user;
  }

  /// Sign in with email + password
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) throw Exception('User profile not found.');
    return UserModel.fromFirestore(doc);
  }

  /// Fetch user profile by ID
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Stream user profile
  Stream<UserModel?> userProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Update FCM token
  Future<void> updateFcmToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Delete Firestore document first
      await _db.collection('users').doc(user.uid).delete();
      // Delete Firebase Auth user
      await user.delete();
    }
  }
}
