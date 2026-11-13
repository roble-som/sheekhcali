import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../l10n/localized_digits.dart';
import 'hijri_date.dart';

/// Display strings for the Home date header and the reader title.
@immutable
class DateLabels {
  const DateLabels({
    required this.weekday,
    required this.hijri,
    required this.hijriPadded,
    required this.gregorian,
  });

  final String weekday;

  /// For example "2 Jumada al-Thani 1448 AH". Null when outside the method's range.
  final String? hijri;

  /// With a two-digit day, as in the reader title ("02 Jumada al-Thani…").
  final String? hijriPadded;
  final String gregorian;

  static DateLabels build({
    required DateTime now,
    required Locale locale,
    required AppLocalizations l10n,
    required HijriDateConverter converter,
  }) {
    final tag = locale.languageCode;
    final h = converter.fromGregorian(now);
    String? hijri;
    String? hijriPadded;
    if (h != null) {
      final month = hijriMonthName(l10n, h.month);
      hijri = localizeDigits(
        l10n.hijriDate('${h.day}', month, '${h.year}'),
        locale,
      );
      hijriPadded = localizeDigits(
        l10n.hijriDate(h.day.toString().padLeft(2, '0'), month, '${h.year}'),
        locale,
      );
    }
    final gregorian = localizeDigits(
      '${DateFormat('d MMMM y', tag).format(now)} ${l10n.gregorianSuffix}',
      locale,
    );
    return DateLabels(
      weekday: DateFormat('EEEE', tag).format(now),
      hijri: hijri,
      hijriPadded: hijriPadded,
      gregorian: gregorian,
    );
  }
}

/// Localised Hijri month names. The Arabic names are draft UI copy pending
/// native review (DESIGN_SYSTEM_SPECIFICATION §6.7).
String hijriMonthName(AppLocalizations l10n, int month) => switch (month) {
  1 => l10n.hijriMonth1,
  2 => l10n.hijriMonth2,
  3 => l10n.hijriMonth3,
  4 => l10n.hijriMonth4,
  5 => l10n.hijriMonth5,
  6 => l10n.hijriMonth6,
  7 => l10n.hijriMonth7,
  8 => l10n.hijriMonth8,
  9 => l10n.hijriMonth9,
  10 => l10n.hijriMonth10,
  11 => l10n.hijriMonth11,
  12 => l10n.hijriMonth12,
  _ => throw RangeError.range(month, 1, 12, 'month'),
};
