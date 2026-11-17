import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../errors.dart';

/// AES-256-GCM, performed entirely on the device.
///
/// Blob layout: [12-byte IV][ciphertext][16-byte GCM tag]
/// The 256-bit key is generated per file and never leaves the device: it only
/// travels inside the share link, which the user controls.
class VaultCrypto {
  const VaultCrypto._();

  static const int keyLength = 32;
  static const int ivLength = 12;
  static const int tagLength = 16;

  static Uint8List randomBytes(int length) {
    final Random random = Random.secure();
    final Uint8List bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  static Uint8List encrypt({
    required Uint8List key,
    required Uint8List plaintext,
  }) {
    final Uint8List iv = randomBytes(ivLength);
    final GCMBlockCipher cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)),
      );
    // process() returns ciphertext || 16-byte tag.
    final Uint8List body = cipher.process(plaintext);

    final BytesBuilder builder = BytesBuilder(copy: false)
      ..add(iv)
      ..add(body);
    return builder.toBytes();
  }

  static Uint8List decrypt({
    required Uint8List key,
    required Uint8List blob,
  }) {
    if (blob.length < ivLength + tagLength) {
      throw const VaultException('This file is too small to be a vault blob.');
    }
    final Uint8List iv = Uint8List.sublistView(blob, 0, ivLength);
    final Uint8List body = Uint8List.sublistView(blob, ivLength);

    try {
      final GCMBlockCipher cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)),
        );
      return cipher.process(body);
    } catch (_) {
      throw const VaultException(
        'Decryption failed: the key is wrong or the file was tampered with.',
      );
    }
  }

  /// URL-safe base64, padding stripped so the link stays copy friendly.
  static String encodeKey(Uint8List key) =>
      base64Url.encode(key).replaceAll('=', '');

  static Uint8List decodeKey(String value) {
    final String padded = base64Url.normalize(value.trim());
    return Uint8List.fromList(base64Url.decode(padded));
  }
}
