import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sheekhcali/core/calendar/date_labels.dart';
import 'package:sheekhcali/core/calendar/hijri_date.dart';
import 'package:sheekhcali/core/l10n/localized_digits.dart';
import 'package:sheekhcali/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  group('HijriDateConverter (Umm al-Qura, provisional default P-11)', () {
    const converter = HijriDateConverter();

    test('reproduces the reference screenshot date', () {
      // Screenshot 01: Thursday 12 November 2026 = 2 Jumada al-Thani 1448 AH.
      expect(
        converter.fromGregorian(DateTime(2026, 11, 12)),
        const HijriDate(day: 2, month: 6, year: 1448),
      );
    });

    test('ignores the time of day', () {
      expect(
        converter.fromGregorian(DateTime(2026, 11, 12, 23, 59)),
        const HijriDate(day: 2, month: 6, year: 1448),
      );
    });

    test('applies the user adjustment in whole days', () {
      const plusOne = HijriDateConverter(adjustmentDays: 1);
      expect(
        plusOne.fromGregorian(DateTime(2026, 11, 12)),
        const HijriDate(day: 3, month: 6, year: 1448),
      );
    });

    test('returns null outside the published table instead of guessing', () {
      expect(converter.fromGregorian(DateTime(1900, 1, 1)), isNull);
      expect(converter.fromGregorian(DateTime(2100, 1, 1)), isNull);
    });
  });

  group('localizeDigits', () {
    test('Arabic UI uses Arabic-Indic digits (P-14 pending)', () {
      expect(localizeDigits('12 / 1448', const Locale('ar')), '١٢ / ١٤٤٨');
    });

    test('English is unchanged', () {
      expect(localizeDigits('12 / 1448', const Locale('en')), '12 / 1448');
    });
  });

  group('DateLabels', () {
    test('English matches the reference header', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final labels = DateLabels.build(
        now: DateTime(2026, 11, 12),
        locale: const Locale('en'),
        l10n: l10n,
        converter: const HijriDateConverter(),
      );
      expect(labels.weekday, 'Thursday');
      expect(labels.hijri, '2 Jumada al-Thani 1448 AH');
      expect(labels.hijriPadded, '02 Jumada al-Thani 1448 AH');
      expect(labels.gregorian, '12 November 2026 CE');
    });

    test('Arabic uses Arabic names and digits', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
      final labels = DateLabels.build(
        now: DateTime(2026, 11, 12),
        locale: const Locale('ar'),
        l10n: l10n,
        converter: const HijriDateConverter(),
      );
      expect(labels.weekday, 'الخميس');
      expect(labels.hijri, '٢ جمادى الآخرة ١٤٤٨ هـ');
      expect(labels.gregorian, '١٢ نوفمبر ٢٠٢٦ م');
    });
  });
}
