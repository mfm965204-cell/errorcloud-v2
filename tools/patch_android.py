#!/usr/bin/env python3
"""Patch the freshly scaffolded Android manifest for Errorcloud.

The Flutter template is regenerated on every CI run, so app-level tweaks live
here rather than in a hand-maintained android/ folder.

Note: the Flutter template only declares android.permission.INTERNET in the
debug/profile manifests, so a release APK has no network access unless it is
added here. That was the cause of "Failed host lookup" in v1.0.0.
"""
from pathlib import Path

MANIFEST = Path("android/app/src/main/AndroidManifest.xml")

PERMISSIONS = (
    '    <uses-permission android:name="android.permission.INTERNET" />\n'
    '    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />\n'
    '    <uses-permission android:name="android.permission.'
    'WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />\n'
)


def main() -> None:
    text = MANIFEST.read_text(encoding="utf-8")

    # Launcher name
    text = text.replace('android:label="errorcloud"', 'android:label="Errorcloud"')

    if "android.permission.INTERNET" not in text:
        text = text.replace("</manifest>", PERMISSIONS + "</manifest>")
    elif "WRITE_EXTERNAL_STORAGE" not in text:
        text = text.replace(
            '    <uses-permission android:name="android.permission.INTERNET" />\n',
            PERMISSIONS,
        )

    MANIFEST.write_text(text, encoding="utf-8")

    for required in (
        "android.permission.INTERNET",
        "android.permission.ACCESS_NETWORK_STATE",
        "WRITE_EXTERNAL_STORAGE",
        'android:label="Errorcloud"',
    ):
        if required not in text:
            raise SystemExit(f"manifest patch failed: missing {required}")

    print(text)


if __name__ == "__main__":
    main()
