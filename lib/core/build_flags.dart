/// A testing build that carries the Sheikh's Al-Fatiha recording (R3) inside
/// the APK, so it plays offline right after a plain install on the owner's
/// own test devices.
///
/// Set only by `--dart-define=SHEEKH_TESTING_AUDIO=true`, which
/// `tool/build_testing_apk.sh` passes; Gradle then verifies the original's
/// SHA-256 and packs it unchanged. Owner decision, 2026-11-13 (C-26 as
/// extended): testing APKs only, never the default or a public build.
const kTestingAudioBuild = bool.fromEnvironment('SHEEKH_TESTING_AUDIO');
