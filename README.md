# sheekhcali
sheekh cali nuur

## Building

The Sheikh's Al-Fatiha recording is bundled in every build but kept out of
Git (all media is). Once per machine, with the original in `shiiq_mp3/`:

```
tool/audio/bundle_r3.sh      # verified, byte-identical copy into assets/audio/
flutter build apk --release  # or --debug
tool/check_apk_audio.sh build/app/outputs/flutter-apk/app-release.apk
```

Release builds use `android/key.properties` when it exists (git-ignored);
without it they are signed with the debug key and are not for publishing.
