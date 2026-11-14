import 'package:flutter/foundation.dart';

/// What kind of audio a recording is. Sheikh lessons and Quran recitation are
/// always labelled differently (DESIGN_SYSTEM_SPECIFICATION §8.11).
enum RecordingKind { tafsir, recitation }

/// What the rights record allows (C-26).
enum RecordingRights {
  /// Development and emulator testing only: never bundled, never in release.
  testingOnly,

  /// May ship inside the app and play in every build (R3 since C-31).
  distribution,
}

/// An original recording, identified by the SHA-256 of its exact bytes. The
/// filename is not identity: R3 was renamed during development and its
/// hash did not change.
@immutable
class RecordingInfo {
  const RecordingInfo({
    required this.id,
    required this.sha256,
    required this.bytes,
    required this.durationMs,
    required this.surah,
    required this.kind,
    required this.rights,
    required this.id3Title,
    required this.id3Artist,
    required this.alignmentAsset,
    this.bundledAsset,
  });

  final String id;
  final String sha256;
  final int bytes;

  /// Measured from the file itself (Xing frame count × 1152 / 44100 Hz).
  final int durationMs;
  final int surah;
  final RecordingKind kind;
  final RecordingRights rights;

  /// Tag values as found in the file. Not proof of identity (P-19).
  final String id3Title;
  final String id3Artist;
  final String alignmentAsset;

  /// The app asset holding a byte-identical copy of the recording, if the
  /// app ships it (pubspec.yaml). Copied to app storage on first use.
  final String? bundledAsset;
}

/// Where the recording stands on this device.
@immutable
sealed class RecordingStatus {
  const RecordingStatus();
}

/// Rights don't allow it in this build (release build, testing-only rights).
final class RecordingNotPermitted extends RecordingStatus {
  const RecordingNotPermitted();
}

/// This platform can't play locally installed recordings (the web build: the
/// testing-only recording is never part of a web bundle, C-26).
final class RecordingPlatformUnsupported extends RecordingStatus {
  const RecordingPlatformUnsupported();
}

/// Not installed on this device. [expectedPath] says where a tester puts it.
final class RecordingNotInstalled extends RecordingStatus {
  const RecordingNotInstalled(this.expectedPath);

  final String expectedPath;
}

/// A file is present but its bytes are not the original's.
final class RecordingChecksumMismatch extends RecordingStatus {
  const RecordingChecksumMismatch(this.actualSha256);

  final String actualSha256;
}

/// A testing build carries the recording, but copying it to app storage
/// failed (for example, the device is out of space). [reason] is technical.
final class RecordingUnpackFailed extends RecordingStatus {
  const RecordingUnpackFailed(this.reason);

  final String reason;
}

/// Present and byte-identical to the original.
final class RecordingReady extends RecordingStatus {
  const RecordingReady(this.path, this.info);

  final String path;
  final RecordingInfo info;
}
