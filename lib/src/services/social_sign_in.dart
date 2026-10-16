import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// What the backend needs to verify a Google or Apple sign-in.
class SocialCredential {
  const SocialCredential(this.path, this.body);

  final String path;
  final Map<String, dynamic> body;
}

class SocialSignIn {
  /// Null when the person closed the Google sheet.
  static Future<SocialCredential?> google() async {
    final google = GoogleSignIn(scopes: const ['email', 'profile']);
    // Always ask which account, instead of silently reusing the last one.
    await google.signOut().catchError((_) => null);
    final account = await google.signIn();
    if (account == null) return null;
    final idToken = (await account.authentication).idToken;
    if (idToken == null) throw Exception('Google did not return a sign-in token');
    return SocialCredential('/auth/google', {
      'credential': idToken,
      'email': account.email,
      'name': account.displayName ?? '',
    });
  }

  /// Null when the person cancelled.
  static Future<SocialCredential?> apple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final name = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
      return SocialCredential('/auth/apple', {
        'identityToken': credential.identityToken,
        'email': credential.email ?? '',
        'name': name,
      });
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }

  static Future<void> signOutGoogle() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }
}
