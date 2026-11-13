import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the bundled fonts' licences to Flutter's licence page (Settings →
/// Content sources & licences → Open-source licences). Package licences are
/// registered by Flutter automatically.
void registerBundledLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Inter (font)',
    ], await rootBundle.loadString('assets/fonts/licenses/Inter-OFL.txt'));
    yield LicenseEntryWithLineBreaks(const [
      'Amiri (Quran text font)',
    ], await rootBundle.loadString('assets/fonts/licenses/Amiri-OFL.txt'));
    yield LicenseEntryWithLineBreaks(
      const ['Noto Sans Arabic, Noto Naskh Arabic (fonts)'],
      await rootBundle.loadString(
        'assets/fonts/licenses/Noto-OFL-and-copyright.txt',
      ),
    );
  });
}
