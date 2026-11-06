# KNL Church — Flutter native app

Native sibling of the WebView app (`com.kisii.church`). This one is
`com.kisii.church.knlapp` ("KNL Church") so both stay installed side by side.

- UI: `lib/main.dart` (single file, Material, KNL navy/gold)
- Content: `assets/` (695-hymn JSON, announcements, logo, photos) — copied
  from the WebView project
- Launcher icons: `android-icons/` (unique KNL mark, 5 densities)
- `android-shell/AndroidManifest.xml` overlays the CI-generated shell
- CI (`.github/workflows/build-apk.yml`) scaffolds the native shell with
  `flutter create` on x86_64 runners (this repo is authored on ARM, where the
  Flutter SDK cannot run), overlays our code, signs with the release
  keystore from Actions secrets, and uploads the APK.

Secrets required: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`,
`KEY_PASSWORD` (same KNL release key as the WebView app).

Backend: `https://knl-stk.spidmax.win` (shared with the WebView app).
