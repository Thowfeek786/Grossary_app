import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:models/models.dart';
import 'package:repository/repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class DeliveryAuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final StorageRepository _storageRepo = StorageRepository();
  final UserRepository _userRepo = UserRepository();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _error;
  bool _isLoading = false;
  StreamSubscription? _userSub;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;

  DeliveryAuthProvider() {
    _init();
  }

  void _init() {
    _authRepo.authStateChanges.listen((User? firebaseUser) async {
       await _userSub?.cancel();
      if (firebaseUser == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
      } else {
        _userSub = _userRepo.getUserStream(firebaseUser.uid).listen((profile) {
          if (profile != null && profile.role == UserRole.deliveryPartner) {
            _user = profile;
            _status = AuthStatus.authenticated;
          } else if (profile != null) {
            _status = AuthStatus.unauthenticated;
            _error = 'Unauthorized. This app is for delivery partners only.';
          } else {
            _status = AuthStatus.unauthenticated;
          }
          notifyListeners();
        });
      }
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _authRepo.signInWithEmail(email: email, password: password);
      if (user.role != UserRole.deliveryPartner) {
        await _authRepo.signOut();
        _error = 'Unauthorized. Use the correct app for your role.';
        return false;
      }
      _user = user;
      _status = AuthStatus.authenticated;
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
        role: UserRole.deliveryPartner,
      );
      _user = user;
      _status = AuthStatus.authenticated;
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

  Future<void> toggleAvailability(bool available) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final updatedUser = _user!.copyWith(isApproved: available); // Re-using isApproved or adding a new field?
      // Actually common to use isActive or a dedicated 'isOnline' field.
      // Let's use isActive for 'Work Mode' in this context.
      await _userRepo.updateUser(_user!.copyWith(isActive: available));
      _user = _user!.copyWith(isActive: available);
    } catch (e) {
      _error = 'Failed to update status.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBankDetails({
    required String bankName,
    required String accountHolder,
    required String accountNumber,
    required String ifscCode,
  }) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final updatedUser = _user!.copyWith(
        bankName: bankName,
        accountHolder: accountHolder,
        accountNumber: accountNumber,
        ifscCode: ifscCode,
      );
      await _userRepo.updateUser(updatedUser);
      _user = updatedUser;
    } catch (e) {
      _error = 'Failed to update bank details.';
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
    await _userSub?.cancel();
    await _authRepo.signOut();
  }
}
