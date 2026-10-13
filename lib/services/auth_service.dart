import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginResult {
  LoginResult.signedIn(this.user) : otpRequired = false, email = '', message = '';

  LoginResult.needsCode({required this.email, this.message = ''})
      : user = null,
        otpRequired = true;

  final User? user;
  final bool otpRequired;
  final String email;
  final String message;
}

class AuthService {
  // Login
  Future<LoginResult> login(String email, String password, {String code = ''}) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'client': 'app',
        if (code.trim().isNotEmpty) 'code': code.trim(),
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['otpRequired'] == true) {
        return LoginResult.needsCode(
          email: data['email']?.toString() ?? email,
          message: data['message']?.toString() ?? 'Code sent to your email',
        );
      }
      final token = data['token'];
      final userData = data['user'];
      await _saveToken(token);
      return LoginResult.signedIn(User.fromJson(userData, token));
    }
    throw Exception(data['message'] ?? 'Failed to login');
  }

  // Register
  Future<User?> register(String name, String email, String phone, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final userData = data['user'];
      
      await _saveToken(token);
      return User.fromJson(userData, token);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to register');
    }
  }

  Future<String> requestOtp(String phone, {String email = ''}) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.otpRequest}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, if (email.trim().isNotEmpty) 'email': email.trim()}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data['message']?.toString() ?? 'Code sent';
    }
    throw Exception(data['message'] ?? 'Could not send a code');
  }

  Future<User?> verifyOtp(String phone, String code, String name) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.otpVerify}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'code': code, 'name': name}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final token = data['token'];
      await _saveToken(token);
      return User.fromJson(data['user'], token);
    }
    throw Exception(data['message'] ?? 'That code was not accepted');
  }

  Future<User?> signInWithGoogle() async {
    final account = await GoogleSignIn(scopes: ['email', 'profile']).signIn();
    if (account == null) return null;

    final idToken = (await account.authentication).idToken;
    if (idToken == null) {
      throw Exception('Google did not return a token');
    }

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'credential': idToken,
        'email': account.email,
        'name': account.displayName ?? '',
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final token = data['token'];
      await _saveToken(token);
      return User.fromJson(data['user'], token);
    }
    throw Exception(data['message'] ?? 'Failed to sign in with Google');
  }

  Future<User?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final given = credential.givenName ?? '';
      final family = credential.familyName ?? '';
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/apple'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identityToken': credential.identityToken,
          'email': credential.email ?? '',
          'name': '$given $family'.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['token'];
        await _saveToken(token);
        return User.fromJson(data['user'], token);
      }
      throw Exception(data['message'] ?? 'Failed to sign in with Apple');
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }

  // Get current user (verify token)
  Future<User?> getMe() async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['user'], token);
    } else {
      await logout();
      return null;
    }
  }

  Future<User?> updateMe(
    String token, {
    required String name,
    String phone = '',
    String city = '',
    String address = '',
  }) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'city': city,
        'address': address,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return User.fromJson(data['user'], token);
    }
    throw Exception(data['message'] ?? 'Failed to update profile');
  }

  Future<void> deleteAccount(String token) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/auth/delete-account'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      await logout();
      return;
    }
    final data = jsonDecode(response.body);
    throw Exception(data['message'] ?? 'Failed to delete account');
  }

  Future<User?> markOnboardingSeen(String token) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/onboarding-seen'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data['user'] != null) {
        return User.fromJson(data['user'], token);
      }
    }
    return null;
  }

  // Save Token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // Get Token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
