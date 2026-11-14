import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/alignment.dart';
import '../domain/recording.dart';

/// R3: the Sheikh's Tafsir of Al-Fatiha, per the owner (C-26). Since C-31
/// (owner, 2026-11-14) it ships in every build: a byte-identical copy is the
/// app asset [RecordingInfo.bundledAsset] (made by tool/audio/bundle_r3.sh).
/// Facts measured from the file on 2026-11-13
/// (docs/content/R3_RECORDING_REPORT.md).
const fatihaTafsirR3 = RecordingInfo(
  id: 'r3-al-fatiha-tafsir-003',
  sha256: '3300e3644ff3631414ffab463d4c34c2ee88da162b77564dd661a187f7b0834f',
  bytes: 12587299,
  durationMs: 2912000,
  surah: 1,
  kind: RecordingKind.tafsir,
  rights: RecordingRights.distribution,
  id3Title: '003-الفاتحة 1-آخرها',
  id3Artist: 'الشيخ علي نور',
  alignmentAsset: 'assets/content/alignments/al-fatiha-tafsir-r3.json',
  bundledAsset: 'assets/audio/al-fatiha-tafsir-r3.mp3',
);

abstract interface class RecordingRepository {
  Future<RecordingStatus> locate(RecordingInfo info);
}

/// Outcome of copying a recording shipped in the app into app storage.
enum UnpackStatus { ok, missing, mismatch, noSpace, error }

/// A recording shipped as an app asset ([RecordingInfo.bundledAsset]),
/// copied out to a file the player can open.
abstract interface class BundledRecordingSource {
  /// Copies the packed recording for [info] to [destPath] atomically,
  /// keeping it only if its SHA-256 and size are the original's.
  Future<(UnpackStatus, String)> unpack(RecordingInfo info, String destPath);
}

/// Android: MainActivity streams the asset out of the APK (channel
/// `sheekhcalinuur/bundled_media`), hashing while copying.
class MethodChannelBundledRecordingSource implements BundledRecordingSource {
  const MethodChannelBundledRecordingSource();

  static const _channel = MethodChannel('sheekhcalinuur/bundled_media');

  @override
  Future<(UnpackStatus, String)> unpack(
    RecordingInfo info,
    String destPath,
  ) async {
    final asset = info.bundledAsset;
    if (asset == null) return (UnpackStatus.missing, 'no bundled asset');
    try {
      final r = await _channel.invokeMapMethod<String, String>('unpack', {
        'asset': asset,
        'dest': destPath,
        'sha256': info.sha256,
        'bytes': info.bytes,
      });
      return (_status(r?['status']), r?['detail'] ?? '');
    } on Object catch (e) {
      return (UnpackStatus.error, '$e');
    }
  }

  static UnpackStatus _status(String? s) => switch (s) {
    'ok' => UnpackStatus.ok,
    'missing' => UnpackStatus.missing,
    'mismatch' => UnpackStatus.mismatch,
    'nospace' => UnpackStatus.noSpace,
    _ => UnpackStatus.error,
  };
}

/// Other platforms (iOS): reads the asset through the asset bundle, checks
/// its SHA-256, writes it to a temporary file and renames it into place.
class AssetBundleRecordingSource implements BundledRecordingSource {
  AssetBundleRecordingSource({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<(UnpackStatus, String)> unpack(
    RecordingInfo info,
    String destPath,
  ) async {
    final asset = info.bundledAsset;
    if (asset == null) return (UnpackStatus.missing, 'no bundled asset');
    final part = File('$destPath.part');
    try {
      final ByteData data;
      try {
        data = await _bundle.load(asset);
      } on FlutterError {
        return (UnpackStatus.missing, asset);
      }
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final actual = sha256.convert(bytes).toString();
      if (bytes.length != info.bytes || actual != info.sha256) {
        return (UnpackStatus.mismatch, actual);
      }
      await part.parent.create(recursive: true);
      await part.writeAsBytes(bytes, flush: true);
      await part.rename(destPath);
      return (UnpackStatus.ok, actual);
    } on FileSystemException catch (e) {
      if (part.existsSync()) part.deleteSync();
      return (UnpackStatus.error, e.message);
    }
  }
}

/// Finds the device's copy of a recording and proves it is the original by
/// its SHA-256 before anything plays it.
///
/// * A recording the app ships ([RecordingInfo.bundledAsset]) is copied on
///   first need to `<app support dir>/dev-media/<sha256>.mp3` (atomically,
///   hashed while copying), and a missing or corrupted copy is replaced the
///   same way. No network, no adb, no manual step.
/// * Without a shipped copy, debug builds accept one installed by
///   `tool/device/install_r3.sh` (developer utility).
/// * Testing-only recordings play only in debug builds.
class LocalRecordingRepository implements RecordingRepository {
  LocalRecordingRepository({
    this.allowTestingOnly = kDebugMode,
    this.bundled,
    Future<Directory> Function()? mediaDirectory,
  }) : _mediaDir = mediaDirectory ?? mediaDir;

  final bool allowTestingOnly;

  /// Where a shipped copy is copied from (null: none on this platform).
  final BundledRecordingSource? bundled;
  final Future<Directory> Function() _mediaDir;
  final _verified = <String, RecordingStatus>{};
  final _inFlight = <String, Future<RecordingStatus>>{};

  static Future<Directory> mediaDir() async =>
      Directory('${(await getApplicationSupportDirectory()).path}/dev-media');

  @override
  Future<RecordingStatus> locate(RecordingInfo info) async {
    if (kIsWeb) return const RecordingPlatformUnsupported();
    if (info.rights == RecordingRights.testingOnly && !allowTestingOnly) {
      return const RecordingNotPermitted();
    }
    final cached = _verified[info.sha256];
    if (cached != null) return cached;
    // One check (and at most one copy) at a time per recording.
    // (The callback must not return the removed future: whenComplete would
    // then wait for the very future it is completing.)
    return _inFlight[info.sha256] ??= _locate(info).whenComplete(() {
      _inFlight.remove(info.sha256);
    });
  }

  Future<RecordingStatus> _locate(RecordingInfo info) async {
    final dir = await _mediaDir();
    final file = File('${dir.path}/${info.sha256}.mp3');
    var status = await _verify(file, info);
    final source = bundled;
    if (status is! RecordingReady && source != null) {
      // Missing or not the original: replace it from the packed copy.
      final (outcome, detail) = await source.unpack(info, file.path);
      switch (outcome) {
        case UnpackStatus.ok:
          status = await _verify(file, info);
        case UnpackStatus.missing:
          break; // Not packed in this build: report what is on the device.
        case UnpackStatus.mismatch:
          status = RecordingChecksumMismatch(detail);
        case UnpackStatus.noSpace:
        case UnpackStatus.error:
          status = RecordingUnpackFailed(detail);
      }
    }
    if (status is RecordingReady) _verified[info.sha256] = status;
    return status;
  }

  Future<RecordingStatus> _verify(File file, RecordingInfo info) async {
    if (!file.existsSync()) return RecordingNotInstalled(file.path);
    if (file.lengthSync() != info.bytes) {
      return const RecordingChecksumMismatch('size differs');
    }
    final actual = await compute(_sha256OfFile, file.path);
    return actual == info.sha256
        ? RecordingReady(file.path, info)
        : RecordingChecksumMismatch(actual);
  }
}

Future<String> _sha256OfFile(String path) async =>
    (await sha256.bind(File(path).openRead()).first).toString();

final recordingRepositoryProvider = Provider<RecordingRepository>(
  (ref) => LocalRecordingRepository(
    bundled: kIsWeb
        ? null
        : defaultTargetPlatform == TargetPlatform.android
        ? const MethodChannelBundledRecordingSource()
        : AssetBundleRecordingSource(),
  ),
);

final fatihaRecordingProvider = FutureProvider<RecordingStatus>(
  (ref) => ref.watch(recordingRepositoryProvider).locate(fatihaTafsirR3),
);

/// The alignment file for a recording (bundled; it contains no audio).
final alignmentProvider = FutureProvider.family<TafsirAlignment?, String>((
  ref,
  asset,
) async {
  try {
    final raw = await rootBundle.loadString(asset, cache: false);
    return TafsirAlignment.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } on Object {
    return null;
  }
});
