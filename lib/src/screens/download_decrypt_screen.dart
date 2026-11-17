import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../errors.dart';
import '../models/vault_link.dart';
import '../services/api_client.dart';
import '../services/vault_crypto.dart';
import '../theme.dart';

class DownloadDecryptScreen extends StatefulWidget {
  const DownloadDecryptScreen({super.key});

  @override
  State<DownloadDecryptScreen> createState() => _DownloadDecryptScreenState();
}

class _DownloadDecryptScreenState extends State<DownloadDecryptScreen> {
  final PinnedApiClient _api = PinnedApiClient();
  final TextEditingController _controller = TextEditingController();

  bool _busy = false;
  String? _error;
  String? _status;

  @override
  void dispose() {
    _controller.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final String? text = data?.text;
    if (text != null && text.isNotEmpty) {
      _controller.text = text.trim();
    }
  }

  Future<void> _downloadAndDecrypt() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _status = null;
    });

    try {
      final VaultLink link = VaultLink.parse(_controller.text);

      final Uint8List blob = await _api.download(link.id);
      final Uint8List plain = VaultCrypto.decrypt(key: link.key, blob: blob);

      final String name = link.fileName ?? 'errorcloud_${link.id}';
      final int dot = name.lastIndexOf('.');
      final String base = dot > 0 ? name.substring(0, dot) : name;
      final String ext =
          dot > 0 && dot < name.length - 1 ? name.substring(dot + 1) : 'bin';

      await FileSaver.instance.saveFile(
        name: base,
        bytes: plain,
        ext: ext,
        mimeType: MimeType.other,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _status = 'Decrypted and saved to Downloads: $name';
      });
      await _showSuccessDialog(name);
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = error is ApiException || error is VaultException
            ? error.toString()
            : 'Download or decryption failed: $error';
      });
    }
  }

  Future<void> _showSuccessDialog(String fileName) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('File decrypted'),
          content: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '$fileName has been saved to your Downloads folder.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Download & Decrypt'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: <Widget>[
            const SectionHeader('Share link'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemGroupedBackground
                      .resolveFrom(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: CupertinoTextField(
                        controller: _controller,
                        placeholder: 'errorcloud://X7F9A2C?key=…',
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: null,
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.url,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: _busy ? null : _paste,
                      child: const Text('Paste'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: kAccent,
                borderRadius: BorderRadius.circular(12),
                onPressed: _busy ? null : _downloadAndDecrypt,
                child: _busy
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : const Text(
                        'Download & Decrypt',
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
            if (_status != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      size: 18,
                      color: CupertinoColors.systemGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _status!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SectionHeader('Note'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'The key travels only inside the link. If the link is lost the '
                'file cannot be recovered — not by you, not by the server.',
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
