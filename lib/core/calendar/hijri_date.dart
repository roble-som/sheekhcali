import 'package:flutter/foundation.dart';
import 'package:hijri/hijri_calendar.dart';

/// Hijri calculation methods the app supports.
///
/// The default method is pending owner decision P-11. Umm al-Qura is the
/// recommended default, and it reproduces the reference screenshot's date
/// (12 November 2026 = 2 Jumada al-Thani 1448).
enum HijriMethod { ummAlQura }

@immutable
class HijriDate {
  const HijriDate({required this.day, required this.month, required this.year});

  final int day;

  /// 1 = Muharram … 12 = Dhu al-Hijjah.
  final int month;
  final int year;

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.day == day &&
      other.month == month &&
      other.year == year;

  @override
  int get hashCode => Object.hash(day, month, year);

  @override
  String toString() => 'HijriDate($day/$month/$year)';
}

/// Converts Gregorian dates to Hijri using a named method plus a user
/// adjustment of whole days, since local moon sighting can differ
/// (QURAN_AND_AUDIO_ACCURACY §3.6).
@immutable
class HijriDateConverter {
  const HijriDateConverter({
    this.method = HijriMethod.ummAlQura,
    this.adjustmentDays = 0,
  }) : assert(adjustmentDays >= -2 && adjustmentDays <= 2);

  final HijriMethod method;
  final int adjustmentDays;

  /// Returns null when [date] is outside the method's published table
  /// (Umm al-Qura: 1356–1500 AH), so callers can hide the date rather than
  /// show a guess.
  HijriDate? fromGregorian(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final adjusted = local.add(Duration(days: adjustmentDays));
    switch (method) {
      case HijriMethod.ummAlQura:
        try {
          final h = HijriCalendar.fromDate(adjusted);
          return HijriDate(day: h.hDay, month: h.hMonth, year: h.hYear);
        } on Object {
          return null;
        }
    }
  }
}
