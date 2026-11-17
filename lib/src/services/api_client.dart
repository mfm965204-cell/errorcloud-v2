import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../app_config.dart';
import '../errors.dart';

/// HTTP client for the vault API with strict TLS certificate pinning.
///
/// The trust store is emptied (`withTrustedRoots: false`) so the platform never
/// accepts a certificate on its own: every connection falls through to
/// [_verifyPin], which compares the SHA-256 fingerprint of the server's leaf
/// certificate against the pin compiled into the APK. A MITM proxy presenting
/// any other certificate — even one signed by a CA the device trusts — fails.
class PinnedApiClient {
  PinnedApiClient({http.Client? client}) : _client = client ?? _buildClient();

  final http.Client _client;

  static http.Client _buildClient() {
    final HttpClient inner = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30);

    if (!AppConfig.pinningEnabled) {
      // No pin injected (local debug build): fall back to normal validation.
      return IOClient(inner);
    }

    final HttpClient pinned = HttpClient(
      context: SecurityContext(withTrustedRoots: false),
    )
      ..connectionTimeout = const Duration(seconds: 30)
      ..badCertificateCallback = _verifyPin;
    return IOClient(pinned);
  }

  static bool _verifyPin(X509Certificate certificate, String host, int port) {
    if (host != AppConfig.apiHost) {
      return false;
    }
    final String fingerprint =
        base64.encode(sha256.convert(certificate.der).bytes);
    return AppConfig.pinnedFingerprints.contains(fingerprint);
  }

  Future<String> upload(Uint8List blob) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('${AppConfig.apiBase}/upload'),
            headers: const <String, String>{
              'Content-Type': 'application/octet-stream',
            },
            body: blob,
          )
          .timeout(const Duration(seconds: 180));
    } on HandshakeException {
      throw const ApiException(
        'TLS pin mismatch — the server certificate is not the pinned one.',
      );
    } on SocketException catch (error) {
      throw ApiException('Network error: ${error.message}');
    }

    if (response.statusCode != 200) {
      throw ApiException('Upload failed (HTTP ${response.statusCode}).');
    }

    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['id'] is! String) {
      throw const ApiException('Unexpected response from the vault service.');
    }
    return decoded['id'] as String;
  }

  Future<Uint8List> download(String id) async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse('${AppConfig.apiBase}/download/$id'))
          .timeout(const Duration(seconds: 180));
    } on HandshakeException {
      throw const ApiException(
        'TLS pin mismatch — the server certificate is not the pinned one.',
      );
    } on SocketException catch (error) {
      throw ApiException('Network error: ${error.message}');
    }

    if (response.statusCode == 404) {
      throw const ApiException('No file is stored under that ID.');
    }
    if (response.statusCode != 200) {
      throw ApiException('Download failed (HTTP ${response.statusCode}).');
    }
    return response.bodyBytes;
  }

  void close() => _client.close();
}
