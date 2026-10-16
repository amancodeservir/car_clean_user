import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api.dart';
import '../services/local_store.dart';
import '../services/notifications.dart';
import '../services/social_sign_in.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Session state. [status] is only `unknown` while the app starts; a sign-in
/// in progress sets [busy] instead, so the router never jumps to the splash
/// screen in the middle of a login.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._store) {
    Api.instance.onUnauthorized = () {
      if (_status == AuthStatus.signedIn) logout();
    };
  }

  final LocalStore _store;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _busy = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get busy => _busy;
  bool get isSignedIn => _status == AuthStatus.signedIn && _user != null;
  String get token => _user?.token ?? '';

  Future<void> start() async {
    final token = _store.token;
    if (token == null || token.isEmpty) {
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    Api.instance.token = token;
    final cached = _store.user;
    try {
      final response = await Api.instance.get('/auth/me');
      await _accept(response['user'], token, fresh: false);
    } on ApiException catch (error) {
      if (error.isUnauthorized || error.isNotFound) {
        await _clear();
      } else if (cached != null) {
        // Offline or a server hiccup: keep the person signed in.
        _user = AppUser.fromJson(cached, token);
        _status = AuthStatus.signedIn;
        notifyListeners();
      } else {
        _status = AuthStatus.signedOut;
        notifyListeners();
      }
    }
  }

  Future<void> signIn(String email, String password) => _run(() async {
        final response = await Api.instance.post('/auth/login', {
          'email': email.trim().toLowerCase(),
          'password': password,
          'client': 'app',
        });
        if (response['otpRequired'] == true) {
          throw ApiException('${response['message'] ?? 'A code was sent to your email'}');
        }
        await _accept(response['user'], '${response['token'] ?? ''}');
      });

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String referralCode = '',
  }) =>
      _run(() async {
        final response = await Api.instance.post('/auth/register', {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'phone': phone.trim(),
          'password': password,
          if (referralCode.trim().isNotEmpty) 'referralCode': referralCode.trim().toUpperCase(),
        });
        await _accept(response['user'], '${response['token'] ?? ''}');
      });

  /// Returns false when the person closed the Google or Apple sheet.
  Future<bool> signInWith(Future<SocialCredential?> Function() provider) async {
    var signedIn = false;
    await _run(() async {
      SocialCredential? credential;
      try {
        credential = await provider();
      } catch (error) {
        debugPrint('Social sign-in failed: $error');
        throw const ApiException('That sign-in is not available on this phone. Use email and password instead.');
      }
      if (credential == null) return;
      final response = await Api.instance.post(credential.path, credential.body);
      await _accept(response['user'], '${response['token'] ?? ''}');
      signedIn = true;
    });
    return signedIn;
  }

  Future<String> forgotPassword(String email) async {
    final response = await Api.instance.post('/auth/password/forgot', {'email': email.trim().toLowerCase()});
    return '${response['message'] ?? 'Check your email for the code'}';
  }

  Future<void> resetPassword({required String email, required String code, required String password}) =>
      _run(() async {
        final response = await Api.instance.post('/auth/password/reset', {
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
          'password': password,
        });
        await _accept(response['user'], '${response['token'] ?? ''}');
      });

  Future<void> updateProfile({required String name, required String phone, String? city, String? address}) async {
    final current = _user;
    if (current == null) throw const ApiException('Please sign in again.', statusCode: 401);
    final response = await Api.instance.put('/auth/me', {
      'name': name.trim(),
      'phone': phone.trim(),
      if (city != null) 'city': city,
      if (address != null) 'address': address,
    });
    await _accept(response['user'], current.token, fresh: false);
  }

  Future<void> refresh() async {
    final current = _user;
    if (current == null) return;
    try {
      final response = await Api.instance.get('/auth/me');
      await _accept(response['user'], current.token, fresh: false);
    } catch (_) {}
  }

  Future<void> markOnboardingSeen() async {
    if (_user == null || _user!.seenOnboarding) return;
    try {
      await Api.instance.post('/auth/onboarding-seen');
    } catch (_) {}
  }

  Future<void> deleteAccount() async {
    await Api.instance.delete('/auth/delete-account');
    await _clear();
  }

  Future<void> logout() async {
    await Notifications.unregisterPush();
    await SocialSignIn.signOutGoogle();
    await _clear();
  }

  Future<void> _run(Future<void> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _accept(dynamic json, String token, {bool fresh = true}) async {
    if (json is! Map || token.isEmpty) {
      throw const ApiException('The server did not return an account. Try again.');
    }
    final map = Map<String, dynamic>.from(json);
    final previousId = _user?.id;
    _user = AppUser.fromJson(map, token);
    _status = AuthStatus.signedIn;
    Api.instance.token = token;
    await _store.setToken(token);
    await _store.setUser(map);
    notifyListeners();
    if (fresh || previousId != _user!.id) {
      Notifications.registerPush();
    }
  }

  Future<void> _clear() async {
    _user = null;
    _status = AuthStatus.signedOut;
    Api.instance.token = null;
    await _store.clearAccount();
    notifyListeners();
  }
}
