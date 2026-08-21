import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:core/core.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AdminAuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _error;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;

  AdminAuthProvider() {
    _init();
  }

  void _init() {
    _authRepo.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
      } else {
        final profile = await _authRepo.getUserProfile(firebaseUser.uid);
        if (profile != null && profile.role == UserRole.admin) {
          _user = profile;
          _status = AuthStatus.authenticated;
        } else {
          await _authRepo.signOut();
          _status = AuthStatus.unauthenticated;
          _error = 'Unauthorized. Admin access required.';
        }
      }
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _authRepo.signInWithEmail(email: email, password: password);
      if (user.role != UserRole.admin) {
        await _authRepo.signOut();
        _error = 'Access denied. Only administrators can login here.';
        return false;
      }
      _user = user;
      _status = AuthStatus.authenticated;
      NotificationService.saveFcmToken(user.id);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _error = 'No administrator account found with this email.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _error = 'Incorrect password. Please check your password or tap "Forgot Password?" to reset.';
      } else if (e.code == 'invalid-email') {
        _error = 'Please enter a valid email address.';
      } else {
        _error = e.message ?? 'Authentication failed.';
      }
      return false;
    } catch (e) {
      _error = 'Login failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authRepo.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Failed to send reset link.';
      return false;
    } catch (e) {
      _error = 'Error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final uid = _user?.id;
    if (uid != null) {
      await NotificationService.removeFcmToken(uid);
    }
    await _authRepo.signOut();
  }
}
