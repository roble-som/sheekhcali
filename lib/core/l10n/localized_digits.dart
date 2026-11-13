import 'package:flutter/widgets.dart';

/// Whether the Arabic UI shows Arabic-Indic digits (٠١٢…).
///
/// Pending owner decision P-14. Arabic-Indic is the recommendation and matches
/// the concept board. Changing this single flag switches the whole Arabic UI.
/// Player time codes keep Western digits regardless (DESIGN_SYSTEM_SPECIFICATION §6).
const bool kArabicIndicDigitsInArabicUi = true;

const _arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Converts Western digits in [input] for display in [locale]. It is only for
/// interface strings such as dates. It is never applied to stored religious
/// text.
String localizeDigits(String input, Locale locale) {
  if (locale.languageCode != 'ar' || !kArabicIndicDigitsInArabicUi) {
    return input;
  }
  final out = StringBuffer();
  for (final unit in input.codeUnits) {
    if (unit >= 0x30 && unit <= 0x39) {
      out.write(_arabicIndic[unit - 0x30]);
    } else {
      out.writeCharCode(unit);
    }
  }
  return out.toString();
}
