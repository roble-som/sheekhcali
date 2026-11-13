// Records the reviewer's on-device check of an imported surah's text
// (QURAN_AND_AUDIO_ACCURACY §3.4, C-27). Only the verification fields change;
// the ayah text and hashes are untouched (the manifest tests prove it).
//
// Usage: dart run tool/quran/sign_off_text.dart --surah 1 --reviewer "<full name>"

import 'dart:convert';
import 'dart:io';

void main(List<String> argv) {
  String? arg(String n) {
    final i = argv.indexOf('--$n');
    return i >= 0 && i + 1 < argv.length ? argv[i + 1] : null;
  }

  final surah = int.tryParse(arg('surah') ?? '');
  final reviewer = arg('reviewer')?.trim();
  if (surah == null || reviewer == null || reviewer.isEmpty) {
    stderr.writeln('Usage: --surah <n> --reviewer "<full name>"');
    exit(1);
  }
  final file = File(
    'assets/quran/tanzil-uthmani-1.1/surah-${surah.toString().padLeft(3, '0')}.json',
  );
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final v = json['verification'] as Map<String, dynamic>;
  if (v['automated'] != 'passed') {
    stderr.writeln(
      'Automated verification has not passed; refusing to sign off.',
    );
    exit(1);
  }
  v['reviewer'] = reviewer;
  v['reviewedAt'] = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(json)}\n',
  );
  stdout.writeln('Signed off surah $surah text check by $reviewer.');
}
