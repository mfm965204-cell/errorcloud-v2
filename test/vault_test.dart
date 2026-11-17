import 'dart:typed_data';

import 'package:errorcloud/src/models/vault_link.dart';
import 'package:errorcloud/src/services/vault_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AES-256-GCM round trip', () {
    final Uint8List key = VaultCrypto.randomBytes(VaultCrypto.keyLength);
    final Uint8List plain = Uint8List.fromList(
      'Errorcloud test payload — Developed by Error'.codeUnits,
    );

    final Uint8List blob = VaultCrypto.encrypt(key: key, plaintext: plain);
    expect(blob.length, plain.length + VaultCrypto.ivLength + VaultCrypto.tagLength);

    final Uint8List out = VaultCrypto.decrypt(key: key, blob: blob);
    expect(out, plain);
  });

  test('wrong key fails authentication', () {
    final Uint8List key = VaultCrypto.randomBytes(VaultCrypto.keyLength);
    final Uint8List blob = VaultCrypto.encrypt(
      key: key,
      plaintext: Uint8List.fromList(<int>[1, 2, 3, 4, 5]),
    );
    final Uint8List otherKey = VaultCrypto.randomBytes(VaultCrypto.keyLength);
    expect(() => VaultCrypto.decrypt(key: otherKey, blob: blob), throwsA(anything));
  });

  test('link round trip keeps the key and file name', () {
    final Uint8List key = VaultCrypto.randomBytes(VaultCrypto.keyLength);
    final VaultLink link = VaultLink(
      id: 'X7F9A2',
      key: key,
      fileName: 'notes final.txt',
    );
    final String shared = link.toShareString();
    expect(shared.startsWith('errorcloud://X7F9A2?key='), isTrue);

    final VaultLink parsed = VaultLink.parse(shared);
    expect(parsed.id, 'X7F9A2');
    expect(parsed.key, key);
    expect(parsed.fileName, 'notes final.txt');
  });

  test('malformed link is rejected', () {
    expect(() => VaultLink.parse('https://example.com'), throwsFormatException);
    expect(() => VaultLink.parse('errorcloud://ABC?key=x'), throwsFormatException);
  });
}
