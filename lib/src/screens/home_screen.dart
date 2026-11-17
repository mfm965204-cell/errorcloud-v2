import 'package:flutter/cupertino.dart';

import '../theme.dart';
import 'about_screen.dart';
import 'download_decrypt_screen.dart';
import 'encrypt_upload_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: kAccent,
        inactiveColor: CupertinoColors.systemGrey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.lock),
            activeIcon: Icon(CupertinoIcons.lock_fill),
            label: 'Encrypt',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.tray_arrow_down),
            activeIcon: Icon(CupertinoIcons.tray_arrow_down_fill),
            label: 'Decrypt',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.info_circle),
            activeIcon: Icon(CupertinoIcons.info_circle_fill),
            label: 'About',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        switch (index) {
          case 0:
            return const CupertinoTabView(
              builder: _encryptBuilder,
              defaultTitle: 'Encrypt & Upload',
            );
          case 1:
            return const CupertinoTabView(
              builder: _decryptBuilder,
              defaultTitle: 'Download & Decrypt',
            );
          default:
            return const CupertinoTabView(
              builder: _aboutBuilder,
              defaultTitle: 'About',
            );
        }
      },
    );
  }
}

Widget _encryptBuilder(BuildContext context) => const EncryptUploadScreen();

Widget _decryptBuilder(BuildContext context) => const DownloadDecryptScreen();

Widget _aboutBuilder(BuildContext context) => const AboutScreen();
