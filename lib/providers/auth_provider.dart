import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/push_registrar.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  bool _otpPending = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get otpPending => _otpPending;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.getMe();
      await _registerPush(_user);
    } catch (e) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password, {String code = ''}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password, code: code);
      if (result.otpRequired) {
        _otpPending = true;
        _error = result.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _user = result.user;
      _otpPending = false;
      await _registerPush(_user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.register(name, email, phone, password);
      await _registerPush(_user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String code, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.verifyOtp(phone, code, name);
      await _registerPush(_user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() => _signInSocial(_authService.signInWithGoogle);

  Future<bool> signInWithApple() => _signInSocial(_authService.signInWithApple);

  Future<bool> _signInSocial(Future<User?> Function() signIn) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await signIn();
      if (user == null) return false;
      _user = user;
      _otpPending = false;
      await _registerPush(user);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateProfile({
    required String name,
    String phone = '',
    String city = '',
    String address = '',
  }) async {
    final token = _user?.token ?? '';
    if (token.isEmpty) return 'Sign in again';
    try {
      final updated = await _authService.updateMe(
        token,
        name: name,
        phone: phone,
        city: city,
        address: address,
      );
      if (updated != null) {
        _user = updated;
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> deleteAccount() async {
    final token = _user?.token ?? '';
    if (token.isEmpty) return 'Sign in again';
    try {
      await _authService.deleteAccount(token);
      _user = null;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<void> _registerPush(User? user) async {
    final token = user?.token ?? '';
    if (token.isEmpty) return;
    try {
      await PushRegistrar.register(token);
    } catch (_) {}
  }

  Future<void> markOnboardingSeen() async {
    final token = _user?.token ?? '';
    if (token.isEmpty) return;
    try {
      final updated = await _authService.markOnboardingSeen(token);
      if (updated != null) {
        _user = updated;
      } else if (_user != null) {
        _user = _user!.copyWith(seenOnboarding: true);
      }
      notifyListeners();
    } catch (_) {
      if (_user != null) {
        _user = _user!.copyWith(seenOnboarding: true);
        notifyListeners();
      }
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
