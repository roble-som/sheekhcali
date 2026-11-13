// Builds docs/review/fatiha_review.html: the reviewer's page for confirming or
// correcting the AI-assisted candidate segments (C-27, C-28).
//
// Usage: dart run tool/review/build_review_page.dart
//
// The page embeds the candidates and the verified Al-Fatiha text (from the
// imported Tanzil asset). It needs the reviewer's own copy of the recording,
// checks its SHA-256 in the browser, and plays segments from exact MP3 frame
// boundaries. Nothing is uploaded; the recording is never modified.

import 'dart:convert';
import 'dart:io';

void main() {
  final candidates = jsonDecode(
    File('docs/review/candidates/r3-candidates.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final text = jsonDecode(
    File('assets/quran/tanzil-uthmani-1.1/surah-001.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final data = {
    'recordingSha256': candidates['recordingSha256'],
    'recordingDurationMs': candidates['recordingDurationMs'],
    'ayahs': [
      for (final a in (text['ayahs'] as List).cast<Map<String, dynamic>>())
        a['text'],
    ],
    'candidates': [
      for (final s
          in (candidates['spans'] as List).cast<Map<String, dynamic>>())
        {
          'id': s['id'],
          'kind': s['kind'],
          'ayahs': s['ayahs'],
          'startMs': s['startMs'],
          'endMs': s['endMs'],
          'confidence': s['confidence'],
          'evidence': _isolateArabic(_escape(s['evidence'] as String)),
          'transcript': _escape(s['transcript'] as String? ?? ''),
          'origin': s['origin'],
        },
    ],
  };
  final template = File('tool/review/fatiha_review_template.html')
      .readAsStringSync();
  final json = jsonEncode(data).replaceAll('</', r'<\/');
  final out = template.replaceFirst('/*DATA*/', json);
  File('docs/review/fatiha_review.html').writeAsStringSync(out);
  stdout.writeln('Wrote docs/review/fatiha_review.html');
}

/// Wraps Arabic runs so quotations keep their order inside English sentences.
String _isolateArabic(String s) => s.replaceAllMapped(
  RegExp(r'[\u0600-\u06FF][\u0600-\u06FF\u064B-\u065F\s/،…]*[\u0600-\u06FF]'),
  (m) => '<bdi dir="rtl">${m[0]}</bdi>',
);

String _escape(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
