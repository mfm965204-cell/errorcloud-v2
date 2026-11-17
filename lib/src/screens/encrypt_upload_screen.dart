import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../errors.dart';
import '../models/vault_link.dart';
import '../services/api_client.dart';
import '../services/vault_crypto.dart';
import '../theme.dart';

class EncryptUploadScreen extends StatefulWidget {
  const EncryptUploadScreen({super.key});

  @override
  State<EncryptUploadScreen> createState() => _EncryptUploadScreenState();
}

class _EncryptUploadScreenState extends State<EncryptUploadScreen> {
  final PinnedApiClient _api = PinnedApiClient();

  String? _fileName;
  int _fileSize = 0;
  Uint8List? _fileBytes;
  bool _busy = false;
  String? _error;
  String? _lastLink;

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  String get _prettySize {
    if (_fileSize < 1024) {
      return '$_fileSize bytes';
    }
    if (_fileSize < 1024 * 1024) {
      return '${(_fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(_fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _pickFile() async {
    setState(() => _error = null);
    try {
      final FilePickerResult? result =
          await FilePicker.platform.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) {
        return;
      }
      final PlatformFile file = result.files.first;
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) {
        setState(() => _error = 'That file could not be read.');
        return;
      }
      final int size = bytes.length;
      setState(() {
        _fileName = file.name;
        _fileSize = size;
        _fileBytes = bytes;
        _lastLink = null;
      });
    } catch (error) {
      setState(() => _error = 'Picking the file failed: $error');
    }
  }

  Future<void> _encryptAndUpload() async {
    final Uint8List? bytes = _fileBytes;
    if (bytes == null || _busy) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // Fresh 256-bit key and 96-bit IV for every file, generated on device.
      final Uint8List key = VaultCrypto.randomBytes(VaultCrypto.keyLength);
      final Uint8List blob = VaultCrypto.encrypt(key: key, plaintext: bytes);

      // Only ciphertext crosses the network.
      final String id = await _api.upload(blob);
      final String share = VaultLink(
        id: id,
        key: key,
        fileName: _fileName,
      ).toShareString();

      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _lastLink = share;
      });
      await _showLinkDialog(share);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = error is ApiException || error is VaultException
            ? error.toString()
            : 'Encryption or upload failed: $error';
      });
    }
  }

  Future<void> _showLinkDialog(String link) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Encrypted & uploaded'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Share this link with the person who should read the file. '
                  'It contains the only copy of the key — Errorcloud cannot '
                  'recover the file without it.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                LinkBox(link),
              ],
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (mounted) {
                  setState(() {});
                }
              },
              child: const Text('Copy to Clipboard'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFile = _fileBytes != null;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Encrypt & Upload'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: <Widget>[
            const SectionHeader('File'),
            CupertinoListSection.insetGrouped(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: CupertinoColors.secondarySystemGroupedBackground,
              children: <Widget>[
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.doc),
                  title: Text(_fileName ?? 'No file selected'),
                  subtitle: hasFile
                      ? Text('$_prettySize · encrypted locally')
                      : const Text('Pick any file from your device'),
                  trailing: const Icon(
                    CupertinoIcons.chevron_forward,
                    size: 18,
                    color: CupertinoColors.tertiaryLabel,
                  ),
                  onTap: _busy ? null : _pickFile,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: kAccent,
                borderRadius: BorderRadius.circular(12),
                onPressed: _busy ? null : _pickFile,
                child: const Text(
                  'Select File',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                borderRadius: BorderRadius.circular(12),
                color: hasFile ? CupertinoColors.black : null,
                disabledColor: CupertinoColors.quaternarySystemFill,
                onPressed: hasFile && !_busy ? _encryptAndUpload : null,
                child: _busy
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : const Text(
                        'Encrypt & Upload',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemRed,
                  ),
                ),
              ),
            if (_lastLink != null) ...<Widget>[
              const SectionHeader('Your share link'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LinkBox(_lastLink!),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: _lastLink!),
                    );
                  },
                  child: const Text('Copy link again'),
                ),
              ),
            ],
            const SectionHeader('How it works'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'AES-256-GCM runs on this device. The server receives an '
                'opaque blob and a random 6-character ID — no file name, no '
                'key, no way to read the contents.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
