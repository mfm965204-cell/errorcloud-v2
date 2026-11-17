# Errorcloud

**Developed by Error**

A zero-knowledge file vault for Android and iOS, built with Flutter and Cloudflare.
Files are encrypted on the device with AES-256-GCM; the server only ever holds
opaque ciphertext under a random six-character ID, and the key travels solely
inside the share link you hand out.

---

## What it does

1. Pick any file in the app.
2. It is encrypted locally with a fresh 256-bit key and a fresh 96-bit IV.
3. Only the ciphertext blob is uploaded to a Cloudflare Worker.
4. You get a link: `errorcloud://X7F9A2?key=BASE64URL_KEY&name=file.pdf`
5. Anyone with the link can decrypt it; nobody else can, including the server.

The backend has no accounts, no file names, no metadata and no keys. Losing the
link means losing the file — there is no recovery path by design.

## Stack

| Layer | Choice |
| --- | --- |
| UI | Flutter, Cupertino widgets (iOS look on every platform) |
| Crypto | AES-256-GCM via `pointycastle`, keys from `Random.secure()` |
| Transport | HTTPS with SHA-256 certificate pinning |
| Backend | Cloudflare Worker (blind storage) |
| Storage | Cloudflare R2 when enabled, Workers KV as the active fallback |
| CI/CD | GitHub Actions → `app-release.apk` artifact |

## Repository layout

```
lib/
  main.dart                     app entry, CupertinoApp
  src/
    app_config.dart             API base + TLS pins (build-time via --dart-define)
    errors.dart                 ApiException / VaultException
    theme.dart                  Cupertino theme, shared widgets
    models/vault_link.dart      errorcloud:// parsing and building
    services/vault_crypto.dart  AES-256-GCM encrypt/decrypt
    services/api_client.dart    pinned HTTP client, upload/download
    screens/                    splash, home tabs, encrypt, decrypt, about
test/vault_test.dart            crypto and link unit tests
worker/worker.js                Cloudflare Worker source
worker/wrangler.toml            Worker config (KV binding active, R2 commented)
tools/patch_android.py          manifest tweaks applied to the CI scaffold
.github/workflows/build-apk.yml APK build pipeline
```

`android/` and `ios/` are not committed: the workflow runs `flutter create` to
scaffold them fresh, then applies `tools/patch_android.py`, so platform files
always match the Flutter version in use.

## Backend

Live Worker: `https://errorcloud-api.mfm965204.workers.dev`

| Endpoint | Behaviour |
| --- | --- |
| `POST /upload` | Raw encrypted bytes in, `{"id":"X7F9A2"}` out |
| `GET /download/:id` | The stored blob as `application/octet-stream` |
| `GET /health` | `{"ok":true,"storage":"kv"}` |

CORS is open (`*`) so the mobile app can call it from any origin. Uploads are
capped at 20 MB.

### Storage note

The Worker prefers an R2 bucket binding named `BUCKET` and falls back to a
Workers KV namespace named `VAULT_KV`. R2 is not enabled on this Cloudflare
account yet (the API returns *"Please enable R2 through the Cloudflare
Dashboard"*), so the deployed Worker currently stores blobs in KV. To switch:

1. Enable R2 in the Cloudflare dashboard (R2 needs a payment method on file).
2. Create the bucket: `npx wrangler r2 bucket create errorcloud-storage`.
3. Uncomment the `[[r2_buckets]]` block in `worker/wrangler.toml`.
4. `npx wrangler deploy`.

No application change is needed — the Worker detects `env.BUCKET` at runtime.

## Encryption details

* Key: 32 random bytes per file, from `Random.secure()`.
* IV: 12 random bytes per file.
* Cipher: AES-256-GCM, 128-bit tag.
* Blob layout: `[12-byte IV][ciphertext][16-byte tag]`.
* Link: `errorcloud://<6-char ID>?key=<base64url key>&name=<optional file name>`.

The key is never sent to the Worker, never logged and never persisted in
plaintext by the app.

## Certificate pinning

`lib/src/services/api_client.dart` builds an `HttpClient` with
`SecurityContext(withTrustedRoots: false)`. Because the trust store is empty,
the platform never accepts a certificate on its own: every connection falls
through to `badCertificateCallback`, which compares the SHA-256 fingerprint of
the server's leaf certificate against the pin compiled into the build. A
man-in-the-middle proxy — even one using a CA the device trusts — fails the
handshake.

The pin is not hardcoded by hand. The workflow reads it from the live
certificate at build time:

```bash
openssl s_client -connect $HOST:443 -servername $HOST </dev/null \
  | openssl x509 -outform der | openssl dgst -sha256 -binary | base64 -w0
```

and injects it with `--dart-define=PINNED_SHA256=…`, so every rebuild carries a
current pin. A spare slot (`PINNED_SHA256_BACKUP`) exists for certificate
rotation: put the next pin there before Cloudflare rotates. Pinning status is
shown on the About screen.

## Build

Local:

```bash
flutter pub get
flutter build apk --release \
  --dart-define=API_BASE=https://errorcloud-api.mfm965204.workers.dev \
  --dart-define=PINNED_SHA256=<base64 sha256 of the live leaf cert>
```

CI: push to `main`. The workflow builds on `ubuntu-latest` with JDK 17 and
Flutter stable, then uploads `app-release.apk` as the `errorcloud-release-apk`
artifact.

## Install

Download `app-release.apk` from the latest successful Actions run, allow
"install unknown apps" for your file manager, and install. The APK is signed
with a CI-generated debug-style key, so Play Protect may warn — that is normal
for sideloaded builds.

## Changelog

**1.0.1** — Release builds now declare `android.permission.INTERNET`. The
Flutter template only adds it to the debug/profile manifests, so v1.0.0 shipped
without network access and every upload failed with *"Failed host lookup"*.
`tools/patch_android.py` now injects `INTERNET` and `ACCESS_NETWORK_STATE` and
fails the build if they are missing. Filled buttons also got explicit white
labels, and DNS failures now show a readable message.

**1.0.0** — First build: AES-256-GCM vault, Cupertino UI, certificate pinning,
Cloudflare blind storage.

## Notes and limits

* `flutter/cupertino.dart` is marked deprecated in favour of `cupertino_ui` in
  very recent Flutter versions; the app builds fine on it and will be migrated
  when the package is the default.
* Artifact links need a GitHub session with access to the repository; artifacts
  expire after 90 days.
* This is a personal project, not an audited product. The crypto is standard
  and the design is sound, but no third-party security review has been done.

---

Developed by Error
