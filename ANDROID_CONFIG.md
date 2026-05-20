# Android App Configuration for Magic Piano Quest

## Build Configuration
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Compile SDK**: 34

## Manifest Settings
### Required Permissions
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Screen Orientation
- Portrait only (lock screen rotation)
- Full screen immersive mode enabled

### Audio Settings
- STREAM_MUSIC focus for audio playback
- Audio session ID for mix compatibility

## Proguard Configuration (Release Builds)
```
-keep class io.flutter.** { *; }
-keep class com.google.android.** { *; }
```

## Performance Settings
- Hardware acceleration enabled
- 60 FPS target (compatible with 90/120Hz displays)
- Automatic frame pacing

## Storage
- App-specific cache directory for temporary assets
- No external storage required
- Minimal file I/O operations

## Release Build Steps
1. `flutter build apk --release`
2. Sign with keystore: `jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 ...`
3. Zipalign: `zipalign -v 4 app-release.apk app-release-aligned.apk`
