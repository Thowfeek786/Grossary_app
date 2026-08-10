import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:core/core.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final UserRepository _userRepo = UserRepository();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _error;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get userId => _user?.id;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authRepo.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
      } else {
        final profile = await _authRepo.getUserProfile(firebaseUser.uid);
        if (profile != null && profile.role == UserRole.customer) {
          _user = profile;
          _status = AuthStatus.authenticated;
        } else {
          await _authRepo.signOut();
          _status = AuthStatus.unauthenticated;
          _error = 'Access denied. Please use the correct app for your role.';
        }
      }
      notifyListeners();
    });
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _error = null;
    try {
      final user = await _authRepo.signInWithGoogle();
      if (user == null) {
        // User cancelled
        return false;
      }
      _user = user;
      _status = AuthStatus.authenticated;
      NotificationService.saveFcmToken(user.id);
      return true;
    } catch (e) {
      _error = 'Google sign-in failed: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final user = await _authRepo.signInWithEmail(email: email, password: password);
      if (user.role != UserRole.customer) {
        await _authRepo.signOut();
        _error = 'Please use the correct app for your role.';
        return false;
      }
      _user = user;
      _status = AuthStatus.authenticated;
      // Save FCM token for push notifications
      NotificationService.saveFcmToken(user.id);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e.code);
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final user = await _authRepo.registerWithEmail(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: UserRole.customer,
      );
      _user = user;
      _status = AuthStatus.authenticated;
      // Save FCM token for push notifications
      NotificationService.saveFcmToken(user.id);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e.code);
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    final uid = _user?.id;
    if (uid != null) {
      await NotificationService.removeFcmToken(uid);
    }
    await _authRepo.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    _setLoading(true);
    _error = null;
    try {
      await _authRepo.deleteAccount();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete account. Please re-login first.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({String? name, String? phone, String? photoUrl}) async {
    if (_user == null) return;
    await _userRepo.updateUserProfile(
      userId: _user!.id,
      name: name,
      phone: phone,
      photoUrl: photoUrl,
    );
    _user = await _authRepo.getUserProfile(_user!.id);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'email-already-in-use': return 'An account already exists with this email.';
      case 'weak-password': return 'Password is too weak.';
      case 'invalid-email': return 'Invalid email address.';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      default: return 'Authentication failed. Please try again.';
    }
  }
}
