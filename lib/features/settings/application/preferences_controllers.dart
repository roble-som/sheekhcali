import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

/// The interface languages: English and Arabic only (C-04).
const supportedAppLocales = [Locale('en'), Locale('ar')];

/// The user's chosen interface language, or null to follow the system.
class LocaleController extends Notifier<Locale?> {
  static const _key = 'ui.locale';

  @override
  Locale? build() {
    final code = ref.watch(sharedPreferencesProvider).getString(_key);
    if (code == null) return null;
    final match = supportedAppLocales.where((l) => l.languageCode == code);
    return match.isEmpty ? null : match.first;
  }

  Future<void> select(Locale? locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

/// Whether reading surfaces use the dark page (screenshot 03, the default) or
/// the provisional light page (G-09).
class ReaderDarkController extends Notifier<bool> {
  static const _key = 'reader.dark';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  Future<void> set({required bool dark}) async {
    state = dark;
    await ref.read(sharedPreferencesProvider).setBool(_key, dark);
  }
}

final readerDarkProvider = NotifierProvider<ReaderDarkController, bool>(
  ReaderDarkController.new,
);

/// "Download on Wi-Fi only". Stored now; the download manager (Phase 2)
/// applies it.
class WifiOnlyController extends Notifier<bool> {
  static const _key = 'downloads.wifiOnly';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  Future<void> set({required bool value}) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

final wifiOnlyProvider = NotifierProvider<WifiOnlyController, bool>(
  WifiOnlyController.new,
);
