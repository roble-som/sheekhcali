import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/features/tafsir_audio/data/recording_repository.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/recording.dart';

/// The Sheikh's Al-Fatiha recording ships in every build (owner decision
/// C-31): it must be listed in pubspec.yaml and the bundled file must be the
/// original, byte for byte (tool/audio/bundle_r3.sh makes it).
void main() {
  final asset = fatihaTafsirR3.bundledAsset!;

  test('pubspec.yaml bundles the recording', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('    - $asset\n'));
  });

  test('the bundled file is the original R3 (size and SHA-256)', () {
    final f = File(asset);
    expect(f.existsSync(), isTrue, reason: 'run tool/audio/bundle_r3.sh');
    expect(f.lengthSync(), fatihaTafsirR3.bytes);
    expect(
      sha256.convert(f.readAsBytesSync()).toString(),
      fatihaTafsirR3.sha256,
    );
  });

  test('it is a distribution recording: no build refuses it', () {
    expect(fatihaTafsirR3.rights, RecordingRights.distribution);
  });
}
