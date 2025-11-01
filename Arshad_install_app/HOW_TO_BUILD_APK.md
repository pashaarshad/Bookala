HOW TO BUILD APK / App Bundle for Bookala (Bulk SMS Sender)

Prerequisites
- Flutter SDK installed and on PATH or adjust BUILD_APK.bat to point to flutter.bat
- Android SDK / Android Studio installed
  - Install SDK Platform (recommended: Android 33/34) and Android SDK Build-Tools
  - Install platform-tools (adb)
- Java JDK (required by Android tooling)

1) Verify environment
```powershell
flutter doctor
```
Fix any issues reported (especially Android toolchain).

2) Configure Android SDK (if installed in custom location)
```powershell
flutter config --android-sdk "C:\Path\to\Android\sdk"
```

3) Add Android platform support (if not already present)
```powershell
flutter create .
```

4) (Optional but recommended) Create a signing keystore for release builds
```powershell
# replace names and path
keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release_key
```
Move `release-key.jks` to `android/app/` (or a secure location). Create a `key.properties` file in the project root with:
```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=release_key
storeFile=android/app/release-key.jks
```
Then update `android/app/build.gradle` signingConfigs to reference `key.properties` - see Flutter docs.

5) Build commands
- Debug APK (quick)
```powershell
flutter build apk --debug
```
- Release APK (unsigned or signed if signing config exists)
```powershell
flutter build apk --release
```
- App Bundle (recommended for Play Store)
```powershell
flutter build appbundle --release
```

6) Locate artifacts
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

7) Install to device
- Copy to device or install with `adb install -r <apk>`

Troubleshooting
- "Android SDK not found": install Android Studio and SDK, then run `flutter doctor` again.
- Signing errors: ensure `key.properties` path and passwords are correct and referenced in Gradle.

Security note
- Keep `release-key.jks` and passwords safe; losing the keystore prevents future updates on Play Store.

References
- https://docs.flutter.dev/deployment/android
- https://developer.android.com/studio
