import 'package:flutter/cupertino.dart';

import '../app_config.dart';
import '../theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('About')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: <Widget>[
            const SizedBox(height: 28),
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF5856D6), Color(0xFFAF52DE)],
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.lock_fill,
                  color: CupertinoColors.white,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                AppConfig.appName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: CupertinoColors.label,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Version ${AppConfig.appVersion}',
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  AppConfig.signature,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: kAccent,
                  ),
                ),
              ),
            ),
            const SectionHeader('Security'),
            CupertinoListSection.insetGrouped(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: CupertinoColors.secondarySystemGroupedBackground,
              children: const <Widget>[
                CupertinoListTile(
                  leading: Icon(CupertinoIcons.lock_shield),
                  title: Text('AES-256-GCM'),
                  subtitle: Text(
                    'Every file gets a fresh 256-bit key and a 96-bit IV. '
                    'Encryption happens on this device.',
                  ),
                ),
                CupertinoListTile(
                  leading: Icon(CupertinoIcons.eye_slash),
                  title: Text('Zero-knowledge'),
                  subtitle: Text(
                    'The key only ever exists inside the share link. It is '
                    'never uploaded and never stored on the server.',
                  ),
                ),
                CupertinoListTile(
                  leading: Icon(CupertinoIcons.checkmark_seal),
                  title: Text('Certificate pinning'),
                  subtitle: Text(
                    'Requests to the vault API are pinned to a SHA-256 '
                    'certificate fingerprint baked into this build.',
                  ),
                  trailing: Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    size: 20,
                    color: CupertinoColors.systemGreen,
                  ),
                ),
              ],
            ),
            const SectionHeader('Service'),
            CupertinoListSection.insetGrouped(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: CupertinoColors.secondarySystemGroupedBackground,
              children: <Widget>[
                CupertinoListTile(
                  title: const Text('API endpoint'),
                  subtitle: Text(
                    AppConfig.apiBase,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                CupertinoListTile(
                  title: const Text('Pin status'),
                  subtitle: Text(
                    AppConfig.pinningEnabled
                        ? '${AppConfig.pinnedFingerprints.length} pin(s) '
                            'enforced at build time'
                        : 'No pin in this build (debug only)',
                  ),
                ),
                const CupertinoListTile(
                  title: Text('Storage'),
                  subtitle: Text(
                    'Cloudflare blind storage — opaque blobs under random '
                    '6-character IDs.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                AppConfig.signature,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.tertiaryLabel,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
