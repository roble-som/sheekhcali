import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheekhcali/features/tafsir_audio/data/recording_repository.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/recording.dart';

/// The recording repository with a packed copy (testing builds). Synthetic
/// bytes stand in for the recording: these tests check the logic (verify,
/// unpack once, replace a bad copy, fail clearly), not R3 itself, which is
/// checked on the device (tool/device/fresh_install_check.sh).
void main() {
  late Directory dir;
  final original = List<int>.generate(4096, (i) => Random(7).nextInt(256));
  final info = RecordingInfo(
    id: 'synthetic',
    sha256: sha256.convert(original).toString(),
    bytes: original.length,
    durationMs: 1000,
    surah: 1,
    kind: RecordingKind.tafsir,
    rights: RecordingRights.testingOnly,
    id3Title: '',
    id3Artist: '',
    alignmentAsset: '',
  );
  File target() => File('${dir.path}/${info.sha256}.mp3');

  setUp(() => dir = Directory.systemTemp.createTempSync('recording_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  LocalRecordingRepository repo({
    BundledRecordingSource? bundled,
    bool allow = true,
  }) => LocalRecordingRepository(
    allowTestingOnly: allow,
    bundled: bundled,
    mediaDirectory: () async => dir,
  );

  test('no packed copy and nothing installed: not installed', () async {
    expect(await repo().locate(info), isA<RecordingNotInstalled>());
  });

  test('first use: the packed copy is unpacked, verified and ready', () async {
    final source = _FakeSource(original);
    final status = await repo(bundled: source).locate(info);
    expect(status, isA<RecordingReady>());
    expect((status as RecordingReady).path, target().path);
    expect(sha256.convert(target().readAsBytesSync()).toString(), info.sha256);
    expect(source.calls, 1);
  });

  test('a valid copy is reused, also after a restart', () async {
    final source = _FakeSource(original);
    await repo(bundled: source).locate(info);
    // A new repository is what a restarted app gets.
    final again = await repo(bundled: source).locate(info);
    expect(again, isA<RecordingReady>());
    expect(source.calls, 1);
  });

  test('simultaneous requests unpack only once', () async {
    final source = _FakeSource(original, delay: true);
    final r = repo(bundled: source);
    final results = await Future.wait([r.locate(info), r.locate(info)]);
    expect(results, everyElement(isA<RecordingReady>()));
    expect(source.calls, 1);
  });

  test('a corrupted copy is replaced by the packed original', () async {
    target().writeAsBytesSync([...original]..[100] ^= 0xFF);
    final source = _FakeSource(original);
    final status = await repo(bundled: source).locate(info);
    expect(status, isA<RecordingReady>());
    expect(source.calls, 1);
    expect(target().readAsBytesSync(), original);
  });

  test('a truncated copy (interrupted copy) is replaced', () async {
    target().writeAsBytesSync(original.sublist(0, 1000));
    final status = await repo(bundled: _FakeSource(original)).locate(info);
    expect(status, isA<RecordingReady>());
  });

  test('without a packed copy, a corrupted copy is refused', () async {
    target().writeAsBytesSync([...original]..[100] ^= 0xFF);
    expect(await repo().locate(info), isA<RecordingChecksumMismatch>());
  });

  test('the result is re-verified: a wrong copy is never played', () async {
    final source = _FakeSource([...original]..[5] ^= 1, claimOk: true);
    expect(
      await repo(bundled: source).locate(info),
      isA<RecordingChecksumMismatch>(),
    );
  });

  test('out of space: a clear failure, no partial file', () async {
    final source = _FakeSource(original, result: UnpackStatus.noSpace);
    final status = await repo(bundled: source).locate(info);
    expect(status, isA<RecordingUnpackFailed>());
    expect(target().existsSync(), isFalse);
  });

  test('not packed in this build: reports not installed', () async {
    final source = _FakeSource(original, result: UnpackStatus.missing);
    expect(
      await repo(bundled: source).locate(info),
      isA<RecordingNotInstalled>(),
    );
  });

  test('a build that may not play testing-only audio never unpacks', () async {
    final source = _FakeSource(original);
    expect(
      await repo(bundled: source, allow: false).locate(info),
      isA<RecordingNotPermitted>(),
    );
    expect(source.calls, 0);
  });
}

/// Copies [bytes] to the destination like the Android side: to a temporary
/// file, renamed into place only when the hash matches (unless [claimOk]
/// pretends it did, to prove Dart verifies again).
class _FakeSource implements BundledRecordingSource {
  _FakeSource(
    this.bytes, {
    this.result = UnpackStatus.ok,
    this.delay = false,
    this.claimOk = false,
  });

  final List<int> bytes;
  final UnpackStatus result;
  final bool delay;
  final bool claimOk;
  int calls = 0;

  @override
  Future<(UnpackStatus, String)> unpack(
    RecordingInfo info,
    String destPath,
  ) async {
    calls++;
    if (delay) await Future<void>.delayed(const Duration(milliseconds: 20));
    if (result != UnpackStatus.ok) return (result, 'synthetic');
    final actual = sha256.convert(bytes).toString();
    if (actual != info.sha256 && !claimOk) {
      return (UnpackStatus.mismatch, actual);
    }
    final part = File('$destPath.part')..writeAsBytesSync(bytes, flush: true);
    part.renameSync(destPath);
    return (UnpackStatus.ok, actual);
  }
}
