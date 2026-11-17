import 'dart:typed_data';

import '../services/vault_crypto.dart';

/// `errorcloud://<ID>?key=<BASE64URL_KEY>&name=<FILE_NAME>`
class VaultLink {
  const VaultLink({required this.id, required this.key, this.fileName});

  final String id;
  final Uint8List key;
  final String? fileName;

  static final RegExp _pattern =
      RegExp(r'^errorcloud://([A-Za-z0-9]{6})(?:\?(.*))?$');

  static VaultLink parse(String raw) {
    final String trimmed = raw.trim();
    final RegExpMatch? match = _pattern.firstMatch(trimmed);
    if (match == null) {
      throw const FormatException(
        'Expected a link like errorcloud://X7F9A2C?key=BASE64KEY',
      );
    }

    final String id = match.group(1)!.toUpperCase();
    final String query = match.group(2) ?? '';
    final Map<String, String> params = Uri.splitQueryString(query);

    final String? key = params['key'];
    if (key == null || key.isEmpty) {
      throw const FormatException('The link has no key parameter.');
    }

    final Uint8List bytes = VaultCrypto.decodeKey(key);
    if (bytes.length != VaultCrypto.keyLength) {
      throw const FormatException('The key in this link is not 256 bits.');
    }

    final String? name = params['name'];
    return VaultLink(
      id: id,
      key: bytes,
      fileName: (name == null || name.isEmpty) ? null : name,
    );
  }

  String toShareString() {
    final StringBuffer buffer = StringBuffer('errorcloud://$id?key=')
      ..write(VaultCrypto.encodeKey(key));
    final String? name = fileName;
    if (name != null && name.isNotEmpty) {
      buffer
        ..write('&name=')
        ..write(Uri.encodeQueryComponent(name));
    }
    return buffer.toString();
  }
}
