# App Store and Google Play release

Checklist for **Hava Mind** (Flutter, `development` / `production` flavors). Keep secrets out of git: use `assets/env/.env.*` (gitignored where applicable), CI secrets, and `--dart-define`.

---

## Versioning

- Bump `version` in [`pubspec.yaml`](../pubspec.yaml) before each submission (`versionName` + `versionCode` / build number).
- Google Play requires monotonically increasing `versionCode`.

---

## Environment and CI

### Production env file

- Production loads [`assets/env/.env.production`](../assets/env/.env.production) (see [`.gitignore`](../.gitignore)). Copy from [`assets/env/.env.example`](../assets/env/.env.example).
- Required keys: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `REVENUECAT_API_KEY`.
- Optional (in-app **Legal** on Profile): `PRIVACY_POLICY_URL`, `TERMS_OF_SERVICE_URL` — HTTPS URLs shown when non-empty.

### `--dart-define` (CI / headless builds)

Same keys can be passed at build time (see [`lib/core/config/environment_config.dart`](../lib/core/config/environment_config.dart) `read()`). Example:

```bash
flutter build appbundle --flavor production -t lib/main_production.dart \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=REVENUECAT_API_KEY=appl_... \
  --dart-define=PRIVACY_POLICY_URL=https://example.com/privacy \
  --dart-define=TERMS_OF_SERVICE_URL=https://example.com/terms
```

Do **not** commit production keys or `.env.production`.

---

## Android (Google Play)

### Upload keystore and `key.properties`

1. Copy [`android/key.properties.example`](../android/key.properties.example) to `android/key.properties` (gitignored).
2. Create an upload keystore (example):

   ```bash
   keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```

3. Point `storeFile` in `key.properties` at the keystore. Paths are resolved from **`android/app`**, e.g. `../upload-keystore.jks` for a file in `android/`.
4. Enable **Play App Signing** in Play Console; keep the upload key password safe.

### Build production AAB

```bash
flutter build appbundle --flavor production -t lib/main_production.dart
```

Confirm `applicationId` is **`com.havamind.app`** (see [`android/app/build.gradle.kts`](../android/app/build.gradle.kts) and flavor config).

### Google Sign-In (OAuth)

Add the **release** keystore **SHA-1** and **SHA-256** to your Google Cloud / Firebase OAuth client for package **`com.havamind.app`**:

```bash
keytool -list -v -keystore android/upload-keystore.jks -alias upload
```

### Play Console (metadata)

- Privacy policy URL (required when collecting user/audio data).
- Terms of service URL (recommended).
- **Data safety** form: align with Supabase, RevenueCat, and any AI processing.
- **Content rating** questionnaire.
- Billing: create subscription / in-app products; match **RevenueCat** product IDs for the production Android app.

---

## iOS (App Store)

### Signing

- Distribution certificate + **App Store** provisioning profile for **`com.havamind.app`** (production scheme).

### Privacy manifest

- [`ios/Runner/PrivacyInfo.xcprivacy`](../ios/Runner/PrivacyInfo.xcprivacy) is included in the Runner target. Update as Apple / SDK requirements change; third-party pods may ship additional manifests.

### Microphone usage string

- Base string in [`ios/Runner/Info.plist`](../ios/Runner/Info.plist); localized overrides in `en.lproj` and `ru.lproj` **InfoPlist.strings**.

### Build production IPA

```bash
flutter build ipa --flavor production -t lib/main_production.dart
```

Ensure Xcode schemes match **Flavorizr** production configuration.

### App Store Connect

- App record; privacy policy URL; encryption export compliance (typically exempt if HTTPS-only — confirm for your case).
- **App Privacy** labels: consistent with Supabase, RevenueCat, audio, purchases.
- **Review notes**: Google OAuth + `havamind://login-callback` (or your configured scheme); test account if required.
- StoreKit products aligned with **RevenueCat** production iOS app.

---

## Deep links and OAuth

- Align **Supabase Auth** redirect URLs and **Google Cloud OAuth** (Android SHA, iOS bundle ID / reversed client ID) for **`com.havamind.app`** only in production.
- See [`android/app/src/main/AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml) and [`ios/Runner/Info.plist`](../ios/Runner/Info.plist).

---

## QA — production flavor

Run a **cold install** of the **production** build against **production** Supabase and **production** RevenueCat keys.

- [ ] Sign in (Google OAuth completes).
- [ ] Record an audio note → upload → processing completes in app.
- [ ] Subscription purchase / restore (sandbox / test tracks as applicable).
- [ ] Sign out.
- [ ] Legal links open in browser (when URLs configured).

```bash
flutter run --flavor production -t lib/main_production.dart
```

---

## Optional automation

No Fastlane/Codemagic is required by this repo; consider **Fastlane** or **Codemagic** for repeatable signed builds and store upload.
