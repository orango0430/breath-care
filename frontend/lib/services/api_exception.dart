/// A failure the server described in its own error envelope, or a transport
/// failure we turned into the same shape.
///
/// The server documents that clients should branch on [code], not on the HTTP
/// status, so that is what callers get. [message] is already user-facing
/// Korean written by the server — show it rather than inventing your own.
class ApiException implements Exception {
  const ApiException(this.code, this.message);

  final String code;
  final String message;

  /// Server-side codes worth branching on. Everything else should fall through
  /// to showing [message].
  static const String unauthorized = 'UNAUTHORIZED';
  static const String invalidCredentials = 'INVALID_CREDENTIALS';
  static const String duplicateEmail = 'DUPLICATE_EMAIL';
  static const String invalidInput = 'INVALID_INPUT';
  static const String poorSignalQuality = 'POOR_SIGNAL_QUALITY';
  static const String insufficientData = 'INSUFFICIENT_DATA';
  static const String reportUnavailable = 'REPORT_UNAVAILABLE';
  static const String invalidSocialToken = 'INVALID_SOCIAL_TOKEN';

  /// Raised locally too: the Google SDK failing is indistinguishable, from the
  /// screen's point of view, from the server having social login switched off.
  static const String socialUnavailable = 'SOCIAL_LOGIN_UNAVAILABLE';

  /// Client-side codes. The server never sends these; we raise them so callers
  /// can handle "no network" with the same `catch (ApiException)` they already
  /// have, instead of a second catch for SocketException.
  static const String networkError = 'NETWORK_ERROR';
  static const String timeout = 'TIMEOUT';
  static const String malformedResponse = 'MALFORMED_RESPONSE';

  /// True when the session is gone and the user has to sign in again.
  bool get requiresLogin => code == unauthorized;

  /// True when retrying the same request might succeed.
  bool get isTransient =>
      code == networkError || code == timeout || code == reportUnavailable;

  @override
  String toString() => 'ApiException($code): $message';
}
