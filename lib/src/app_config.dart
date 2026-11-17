/// Build-time configuration.
///
/// `API_BASE`, `PINNED_SHA256` and `PINNED_SHA256_BACKUP` are injected by the
/// GitHub Actions workflow with `--dart-define`. The pin is read from the live
/// certificate of the vault API at build time, so a rebuilt APK always carries
/// a current pin.
class AppConfig {
  const AppConfig._();

  static const String appName = 'Errorcloud';
  static const String appVersion = '1.0.1';
  static const String signature = 'Developed by Error';

  /// Blind storage backend (Cloudflare Worker).
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://errorcloud-api.mfm965204.workers.dev',
  );

  /// Base64 SHA-256 fingerprint of the API server's leaf certificate (DER).
  static const String pinnedSha256 = String.fromEnvironment('PINNED_SHA256');

  /// Spare pin, used during certificate rotation.
  static const String pinnedSha256Backup =
      String.fromEnvironment('PINNED_SHA256_BACKUP');

  static String get apiHost => Uri.parse(apiBase).host;

  static List<String> get pinnedFingerprints {
    return <String>[pinnedSha256, pinnedSha256Backup]
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static bool get pinningEnabled => pinnedFingerprints.isNotEmpty;
}
