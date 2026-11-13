/// Folding for **interface search only**: it produces a derived key and never
/// changes stored or displayed text (QURAN_AND_AUDIO_ACCURACY §3.1).
///
/// Arabic: removes harakat, Quranic annotation marks, the superscript alef and
/// tatweel, and folds the alef forms (أ إ آ ٱ → ا). Latin: lower-cases and
/// drops apostrophes, hyphens and spaces, so "al-fatiha", "Al Fatiha" and
/// "alfatiha" match. Arabic-Indic digits fold to Western digits.
///
/// The full search normaliser (with its offset map and reviewed folding rules)
/// comes in Phase 2. This subset covers the index screens.
String foldForSearch(String input) {
  final out = StringBuffer();
  for (final rune in input.runes) {
    if (_isDroppedMark(rune)) continue;
    if (rune == 0x0623 || rune == 0x0625 || rune == 0x0622 || rune == 0x0671) {
      out.writeCharCode(0x0627);
      continue;
    }
    if (rune >= 0x0660 && rune <= 0x0669) {
      out.writeCharCode(0x30 + rune - 0x0660);
      continue;
    }
    if (rune == 0x27 ||
        rune == 0x2019 ||
        rune == 0x2018 ||
        rune == 0x60 ||
        rune == 0x2D ||
        rune == 0x20) {
      continue;
    }
    out.write(String.fromCharCode(rune).toLowerCase());
  }
  return out.toString();
}

bool _isDroppedMark(int cp) =>
    (cp >= 0x064B && cp <= 0x065F) || // harakat, tanwin, shadda, sukun, etc.
    cp == 0x0670 || // superscript alef
    cp == 0x0640 || // tatweel
    (cp >= 0x0610 && cp <= 0x061A) ||
    (cp >= 0x06D6 && cp <= 0x06ED) ||
    (cp >= 0x08D3 && cp <= 0x08FF);
