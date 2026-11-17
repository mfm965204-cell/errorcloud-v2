#!/usr/bin/env python3
"""Patch the freshly scaffolded Android manifest for Errorcloud.

The Flutter template is regenerated on every CI run, so app-level tweaks live
here rather than in a hand-maintained android/ folder.
"""
from pathlib import Path

MANIFEST = Path("android/app/src/main/AndroidManifest.xml")


def main() -> None:
    text = MANIFEST.read_text(encoding="utf-8")

    # Launcher name
    text = text.replace('android:label="errorcloud"', 'android:label="Errorcloud"')

    # file_saver needs legacy write access on Android 9 and below only.
    permission = (
        '    <uses-permission android:name="android.permission.'
        'WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />\n'
    )
    if "WRITE_EXTERNAL_STORAGE" not in text:
        text = text.replace("</manifest>", permission + "</manifest>")

    MANIFEST.write_text(text, encoding="utf-8")
    print(MANIFEST.read_text(encoding="utf-8"))


if __name__ == "__main__":
    main()
