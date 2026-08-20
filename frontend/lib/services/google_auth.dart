import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'api_exception.dart';

/// Turns a "Google로 계속하기" tap into a token our server accepts.
///
/// The token goes to the server exactly as Google issued it. There used to be
/// a Firebase Auth exchange in the middle — sign in to Firebase with the Google
/// credential, then send Firebase's own token, because that is what the server
/// knew how to check. It added two round trips and three ways to fail, and it
/// tied signing in to Firebase Auth being configured. The server verifies
/// Google's signature directly now, so none of that is in the path.
class GoogleAuth {
  const GoogleAuth._();

  static const GoogleAuth instance = GoogleAuth._();

  /// The web client (`client_type: 3`) from google-services.json.
  ///
  /// Android has its own client id, but asking for it back as an *ID token*
  /// requires naming the web client as the audience — without this the sign-in
  /// still succeeds and `idToken` comes back null.
  static const String _serverClientId =
      '830896594990-cgu36rgv13olqegmgf5496q52pmrkqrs.apps.googleusercontent.com';

  static bool _initialized = false;

  /// Returns Google's ID token, or null when the user backed out.
  ///
  /// Throws [ApiException] when sign-in itself fails, so the caller can show
  /// the message as-is. The parenthesised codes are deliberate: the only person
  /// who can retry this is holding a phone with no debugger attached, so the
  /// message has to carry enough to say which step gave up.
  Future<String?> idToken() async {
    try {
      if (!_initialized) {
        await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
        _initialized = true;
      }

      final account = await GoogleSignIn.instance.authenticate();
      final googleIdToken = account.authentication.idToken;
      if (googleIdToken == null) {
        throw const ApiException(
          ApiException.socialUnavailable,
          '구글 인증 정보를 받지 못했어요. (E2 구글토큰없음)',
        );
      }

      // Straight to our server. The Google token used to be swapped for a
      // Firebase one first, because that is what the server verified — two
      // extra round trips through Firebase Auth, and every one of them a place
      // for the login to die. The server now checks Google's signature itself.
      debugPrint('Google ID token length: ${googleIdToken.length}');
      return googleIdToken;
    } on GoogleSignInException catch (e) {
      // Backing out of the account picker is a normal thing to do, not a
      // failure worth showing a red banner for.
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      debugPrint('GoogleSignInException: ${e.code} ${e.description}');
      throw ApiException(ApiException.socialUnavailable, _messageFor(e));
    }
  }

  /// Signs out of Google as well, so the next tap shows the account picker
  /// instead of silently reusing the last account.
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Nothing the user can do about it, and they are being logged out
      // locally either way.
    }
  }

  String _messageFor(GoogleSignInException e) {
    // The usual cause on a real phone: this build's signing certificate is not
    // registered on the Firebase project, so Google refuses before any UI.
    if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
      return '구글 로그인 설정이 맞지 않아요. (E5 설정오류)';
    }
    return '구글 로그인에 실패했어요. (E5 ${e.code.name})';
  }
}
