import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calendar/hijri_date.dart';

/// Current time. Overridden in tests to pin the reference date.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Preferences store, created in `bootstrap()` and overridden in tests.
/// It holds only preferences (language, reading theme), never content or user
/// data. User data goes to Drift `user.db` in Phase 2.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

/// User adjustment of the Hijri date in whole days, −2…+2, because local
/// moon sighting can differ (P-11; QURAN_AND_AUDIO_ACCURACY §3.6).
class HijriAdjustmentController extends Notifier<int> {
  static const _key = 'hijri.adjustment';

  @override
  int build() =>
      (ref.watch(sharedPreferencesProvider).getInt(_key) ?? 0).clamp(-2, 2);

  Future<void> set(int days) async {
    final v = days.clamp(-2, 2);
    state = v;
    await ref.read(sharedPreferencesProvider).setInt(_key, v);
  }
}

final hijriAdjustmentProvider =
    NotifierProvider<HijriAdjustmentController, int>(
      HijriAdjustmentController.new,
    );

/// Hijri conversion: the provisional Umm al-Qura method (C-19) plus the
/// user's adjustment. Every screen uses this provider.
final hijriConverterProvider = Provider<HijriDateConverter>(
  (ref) =>
      HijriDateConverter(adjustmentDays: ref.watch(hijriAdjustmentProvider)),
);

/// How long the splash stays visible at minimum (DESIGN_SYSTEM_SPECIFICATION §8.1).
final splashMinDurationProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 400),
);
