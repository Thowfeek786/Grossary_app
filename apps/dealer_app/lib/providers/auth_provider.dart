import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';
import 'package:core/core.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class DealerAuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final UserRepository _userRepo = UserRepository();
  final StorageRepository _storageRepo = StorageRepository();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _error;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;

  DealerAuthProvider() {
    _init();
  }

  void _init() {
    _authRepo.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
      } else {
        try {
          final profile = await _authRepo.getUserProfile(firebaseUser.uid);
          if (profile != null && profile.role == UserRole.dealer) {
            _user = profile;
            _status = AuthStatus.authenticated;
          } else {
            if (profile != null) {
              await _authRepo.signOut();
              _status = AuthStatus.unauthenticated;
              _error = 'Unauthorized. This app is for dealers only.';
            }
          }
        } catch (_) {
           _status = AuthStatus.unauthenticated;
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
      if (user.role != UserRole.dealer) {
        await _authRepo.signOut();
        _error = 'Unauthorized. Use the correct app for your role.';
        return false;
      }
      _user = user;
      _status = AuthStatus.authenticated;
      NotificationService.saveFcmToken(user.id);
      return true;
    } catch (e) {
      _error = 'Login failed. Please check your credentials.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup({required String name, required String email, required String phone, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _authRepo.registerWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: UserRole.dealer,
      );
      _user = user;
      _status = AuthStatus.authenticated;
      NotificationService.saveFcmToken(user.id);
      return true;
    } catch (e) {
      _error = 'Registration failed. ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfileImage(File imageFile) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final url = await _storageRepo.uploadUserAvatar(imageFile, _user!.id);
      await _userRepo.updateUser(_user!.copyWith(photoUrl: url));
      _user = _user!.copyWith(photoUrl: url);
    } catch (e) {
      _error = 'Failed to upload image.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({String? name, String? phone, String? shopName, String? shopAddress, double? latitude, double? longitude}) async {
    if (_user == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _userRepo.updateUserProfile(
        userId: _user!.id,
        name: name,
        phone: phone,
        shopName: shopName,
        shopAddress: shopAddress,
        latitude: latitude,
        longitude: longitude,
      );
      _user = await _userRepo.getUserById(_user!.id);
    } catch (e) {
      _error = 'Failed to update profile details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepo.deleteAccount();
      _user = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _error = 'Failed to delete account. Please re-login first.';
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
