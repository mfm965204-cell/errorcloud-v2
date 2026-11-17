import 'package:flutter/cupertino.dart';

/// Accent used across the app (iOS system indigo).
const Color kAccent = Color(0xFF5856D6);

final CupertinoThemeData errorcloudTheme = CupertinoThemeData(
  brightness: Brightness.light,
  primaryColor: kAccent,
  primaryContrastingColor: CupertinoColors.white,
  scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
  barBackgroundColor: const Color(0xF2F9F9F9),
  textTheme: const CupertinoTextThemeData(
    primaryColor: kAccent,
    navLargeTitleTextStyle: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: CupertinoColors.label,
    ),
    navTitleTextStyle: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: CupertinoColors.label,
    ),
  ),
);

/// Small uppercase caption used above list sections.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 24, 34, 7),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12.5,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w500,
          color: CupertinoColors.secondaryLabel,
        ),
      ),
    );
  }
}

/// Rounded monospaced surface used for the shareable link.
class LinkBox extends StatelessWidget {
  const LinkBox(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Menlo',
          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          fontSize: 12.5,
          height: 1.4,
          color: CupertinoColors.label,
        ),
      ),
    );
  }
}
