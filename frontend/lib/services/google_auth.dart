import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'api_exception.dart';

/// Turns a "Google로 계속하기" tap into a token our server accepts.
///
/// Two tokens are involved and they are not interchangeable. Google hands back
/// its own ID token; the server calls `FirebaseAuth.verifyIdToken`, which only
/// accepts a **Firebase** ID token. So the Google token is exchanged for a
/// Firebase session first, and it is that session's token we send on.
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

  /// Returns a Firebase ID token, or null when the user backed out.
  ///
  /// Throws [ApiException] when sign-in itself fails, so the caller can show
  /// the message as-is.
  Future<String?> idToken() async {
    // The parenthesised codes are deliberate. The only person who can retry
    // this is holding a phone with no debugger attached, so the message has to
    // carry enough to say which step gave up.
    if (Firebase.apps.isEmpty) {
      throw const ApiException(
        ApiException.socialUnavailable,
        '구글 로그인을 사용할 수 없어요. (E1 Firebase없음)',
      );
    }

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

      final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Not `getIdToken()` on a cached user — this one was just minted, so it
      // is guaranteed fresh for the round trip to our server.
      final firebaseToken = await result.user?.getIdToken();
      if (firebaseToken == null || firebaseToken.isEmpty) {
        throw const ApiException(
          ApiException.socialUnavailable,
          '구글 로그인에 실패했어요. (E4 토큰없음)',
        );
      }
      debugPrint('Firebase ID token length: ${firebaseToken.length}');
      return firebaseToken;
    } on GoogleSignInException catch (e) {
      // Backing out of the account picker is a normal thing to do, not a
      // failure worth showing a red banner for.
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      debugPrint('GoogleSignInException: ${e.code} ${e.description}');
      throw ApiException(ApiException.socialUnavailable, _messageFor(e));
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} ${e.message}');
      throw ApiException(
        ApiException.socialUnavailable,
        e.code == 'operation-not-allowed'
            ? '구글 로그인이 아직 열려 있지 않아요. (E3 제공자꺼짐)'
            : '구글 로그인에 실패했어요. (E3 ${e.code})',
      );
    }
  }

  /// Signs out of Google as well, so the next tap shows the account picker
  /// instead of silently reusing the last account.
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
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
