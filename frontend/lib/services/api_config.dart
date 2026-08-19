/// Server connection settings.
///
/// The default points at the deployed Railway instance so a release APK works
/// with no extra setup. Override it when running against a local backend:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
/// ```
///
/// Note that a plain `http://` URL is blocked on Android 9+ unless a network
/// security config allows cleartext. The Railway URL is https, so the default
/// path needs no such exception.
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://breath-care-production.up.railway.app',
  );

  /// Signal upload carries ~1800 samples, so it needs more room than a plain
  /// GET. The AI report is slower still: it calls an external model and can
  /// take several seconds on a cache miss.
  static const Duration timeout = Duration(seconds: 20);
  static const Duration reportTimeout = Duration(seconds: 60);
}
