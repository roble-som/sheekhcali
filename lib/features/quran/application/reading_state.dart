import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

/// A place in the Quran: surah and ayah, in the source's own numbering.
@immutable
class AyahRef {
  const AyahRef(this.surah, this.ayah);

  final int surah;
  final int ayah;

  /// "surah:ayah", the stored form.
  String encode() => '$surah:$ayah';

  static AyahRef? decode(String? s) {
    final parts = s?.split(':');
    if (parts == null || parts.length != 2) return null;
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null) return null;
    if (surah < 1 || surah > 114 || ayah < 1 || ayah > 286) return null;
    return AyahRef(surah, ayah);
  }

  @override
  bool operator ==(Object other) =>
      other is AyahRef && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);

  @override
  String toString() => encode();
}

/// Where the reader was last: updated as the user reads, taps or scrolls.
/// "Continue reading" (Home, drawer "Recent page") opens it.
class LastReadController extends Notifier<AyahRef?> {
  static const _key = 'quran.lastRead';

  @override
  AyahRef? build() =>
      AyahRef.decode(ref.watch(sharedPreferencesProvider).getString(_key));

  Future<void> set(AyahRef place) async {
    if (state == place) return;
    state = place;
    await ref.read(sharedPreferencesProvider).setString(_key, place.encode());
  }
}

final lastReadProvider = NotifierProvider<LastReadController, AyahRef?>(
  LastReadController.new,
);

/// Ayah bookmarks, newest first. Stored on this device only.
class BookmarksController extends Notifier<List<AyahRef>> {
  static const _key = 'quran.bookmarks';

  @override
  List<AyahRef> build() {
    final raw = ref.watch(sharedPreferencesProvider).getStringList(_key);
    return List.unmodifiable([
      for (final s in raw ?? const <String>[]) ?AyahRef.decode(s),
    ]);
  }

  bool contains(AyahRef place) => state.contains(place);

  /// Adds [place] if absent, removes it if present. Returns true if added.
  Future<bool> toggle(AyahRef place) async {
    final added = !state.contains(place);
    state = List.unmodifiable(
      added ? [place, ...state] : state.where((p) => p != place),
    );
    await ref.read(sharedPreferencesProvider).setStringList(_key, [
      for (final p in state) p.encode(),
    ]);
    return added;
  }
}

final bookmarksProvider = NotifierProvider<BookmarksController, List<AyahRef>>(
  BookmarksController.new,
);

/// Quran text size in logical pixels (the reading default is 28).
class QuranFontSizeController extends Notifier<double> {
  static const _key = 'quran.fontSize';
  static const min = 22.0;
  static const max = 40.0;
  static const standard = 28.0;
  static const step = 2.0;

  @override
  double build() =>
      (ref.watch(sharedPreferencesProvider).getDouble(_key) ?? standard).clamp(
        min,
        max,
      );

  Future<void> set(double size) async {
    state = size.clamp(min, max);
    await ref.read(sharedPreferencesProvider).setDouble(_key, state);
  }
}

final quranFontSizeProvider = NotifierProvider<QuranFontSizeController, double>(
  QuranFontSizeController.new,
);
