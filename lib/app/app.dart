import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/settings/application/preferences_controllers.dart';
import '../features/tafsir_audio/data/recording_repository.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';

class SheekhCalinuurApp extends ConsumerWidget {
  const SheekhCalinuurApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Start verifying (and on first launch unpacking) the Sheikh's recording
    // in the background at app start; the reader finds it ready.
    ref.listen(fatihaRecordingProvider, (_, _) {});
    final chosen = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: chosen,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (device, supported) {
        if (device != null) {
          for (final l in supported) {
            if (l.languageCode == device.languageCode) return l;
          }
        }
        return const Locale('en');
      },
      builder: (context, child) {
        // The theme depends on the resolved locale (Arabic vs Latin fonts).
        final locale = Localizations.localeOf(context);
        return Theme(data: AppTheme.home(locale), child: child!);
      },
      theme: AppTheme.home(chosen ?? const Locale('en')),
    );
  }
}
