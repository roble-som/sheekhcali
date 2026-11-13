import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/alignment.dart';
import '../domain/recording.dart';

/// R3: the Sheikh's Tafsir of Al-Fatiha, per the owner (C-26). Facts measured
/// from the file on 2026-11-13 (docs/content/R3_RECORDING_REPORT.md).
const fatihaTafsirR3 = RecordingInfo(
  id: 'r3-al-fatiha-tafsir-003',
  sha256: '3300e3644ff3631414ffab463d4c34c2ee88da162b77564dd661a187f7b0834f',
  bytes: 12587299,
  durationMs: 2912000,
  surah: 1,
  kind: RecordingKind.tafsir,
  rights: RecordingRights.testingOnly,
  id3Title: '003-الفاتحة 1-آخرها',
  id3Artist: 'الشيخ علي نور',
  alignmentAsset: 'assets/content/alignments/al-fatiha-tafsir-r3.json',
);

abstract interface class RecordingRepository {
  Future<RecordingStatus> locate(RecordingInfo info);
}

/// Finds a locally installed copy of a recording and proves it is the
/// original by its SHA-256. Nothing is bundled with the app (C-26).
///
/// Testers install the file at `<app support dir>/dev-media/<sha256>.mp3`
/// (docs/review/AL_FATIHA_TAFSIR_REVIEW.md shows the adb commands).
class LocalRecordingRepository implements RecordingRepository {
  LocalRecordingRepository({this.allowTestingOnly = kDebugMode});

  final bool allowTestingOnly;
  final _verified = <String, RecordingStatus>{};

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
    final dir = await mediaDir();
    final file = File('${dir.path}/${info.sha256}.mp3');
    if (!file.existsSync()) return RecordingNotInstalled(file.path);
    if (file.lengthSync() != info.bytes) {
      return const RecordingChecksumMismatch('size differs');
    }
    final actual = await compute(_sha256OfFile, file.path);
    final status = actual == info.sha256
        ? RecordingReady(file.path, info)
        : RecordingChecksumMismatch(actual);
    if (status is RecordingReady) _verified[info.sha256] = status;
    return status;
  }
}

Future<String> _sha256OfFile(String path) async =>
    (await sha256.bind(File(path).openRead()).first).toString();

final recordingRepositoryProvider = Provider<RecordingRepository>(
  (ref) => LocalRecordingRepository(),
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
