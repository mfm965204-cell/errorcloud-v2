import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../app_config.dart';
import '../theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute<void>(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF5856D6), Color(0xFFAF52DE)],
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x335856D6),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.lock_fill,
                color: CupertinoColors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              AppConfig.appName,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Zero-knowledge file vault',
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 28),
            const CupertinoActivityIndicator(radius: 11),
            const SizedBox(height: 40),
            Text(
              AppConfig.signature,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: kAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
