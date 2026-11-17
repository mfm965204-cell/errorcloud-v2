import 'package:flutter/cupertino.dart';

import 'src/screens/splash_screen.dart';
import 'src/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ErrorcloudApp());
}

class ErrorcloudApp extends StatelessWidget {
  const ErrorcloudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Errorcloud',
      debugShowCheckedModeBanner: false,
      theme: errorcloudTheme,
      home: const SplashScreen(),
    );
  }
}
