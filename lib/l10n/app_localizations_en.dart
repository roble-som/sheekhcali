// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sheekh Calinuur';

  @override
  String get appTagline => 'Islamic Digital Learning Platform';

  @override
  String get splashPreparing => 'Preparing your library…';

  @override
  String hijriDate(String day, String month, String year) {
    return '$day $month $year AH';
  }

  @override
  String get gregorianSuffix => 'CE';

  @override
  String get hijriMonth1 => 'Muharram';

  @override
  String get hijriMonth2 => 'Safar';

  @override
  String get hijriMonth3 => 'Rabi al-Awwal';

  @override
  String get hijriMonth4 => 'Rabi al-Thani';

  @override
  String get hijriMonth5 => 'Jumada al-Awwal';

  @override
  String get hijriMonth6 => 'Jumada al-Thani';

  @override
  String get hijriMonth7 => 'Rajab';

  @override
  String get hijriMonth8 => 'Shaban';

  @override
  String get hijriMonth9 => 'Ramadan';

  @override
  String get hijriMonth10 => 'Shawwal';

  @override
  String get hijriMonth11 => 'Dhu al-Qadah';

  @override
  String get hijriMonth12 => 'Dhu al-Hijjah';

  @override
  String get openMenu => 'Open navigation menu';

  @override
  String get dhikrOfTheDay => 'Dhikr of the Day';

  @override
  String get placeholderDhikrArabic =>
      'Verified Arabic dhikr text · source pending (P-12)';

  @override
  String get placeholderDhikrTranslation =>
      'Named translation · pending (P-12)';

  @override
  String get placeholderDhikrReference =>
      'Reference line: collection and number (DV-03)';

  @override
  String get placeholderPhoto => 'Photo placeholder · rights needed';

  @override
  String get placeholderLogo => 'Logo';

  @override
  String get placeholderIllustration => 'Illustration';

  @override
  String placeholderSemantics(String label) {
    return 'Placeholder: $label';
  }

  @override
  String get quranCardTitle => 'Quran';

  @override
  String get quranCardSubtitle => 'Read, Listen, Tafsir & Explore';

  @override
  String get explore => 'Explore';

  @override
  String get khatmahTitle => 'Khatmah';

  @override
  String get khatmahSubtitle => 'Complete the Quran · Individual & Team';

  @override
  String get prayerTitle => 'Prayer Times & Qibla';

  @override
  String get prayerSubtitle => 'Adhan times · Qibla direction';

  @override
  String get libraryTitle => 'Library';

  @override
  String get librarySubtitle => 'Islamic books · Read offline';

  @override
  String get lessonsTitle => 'Sheikh\'s Lessons';

  @override
  String get lessonsSubtitle => 'Original recordings · Listen & follow';

  @override
  String get navHome => 'Home';

  @override
  String get navLibrary => 'Library';

  @override
  String get navLessons => 'Sheikh\'s Lessons';

  @override
  String get navTafsir => 'Tafsir';

  @override
  String get navDownloads => 'Downloads';

  @override
  String get navRecentPage => 'Recent Page';

  @override
  String get navIndexBookmark => 'Index & Bookmark';

  @override
  String get navMyNotes => 'My Notes';

  @override
  String get navItqan => 'Itqan';

  @override
  String get navStatistics => 'Statistics';

  @override
  String get navRecitationCorrection => 'Recitation Correction';

  @override
  String get navLearnHowToUse => 'Learn How to Use!';

  @override
  String get navSettings => 'Settings';

  @override
  String get navAbout => 'About';

  @override
  String get navLiveChat => 'Live Chat';

  @override
  String get drawerBannerPlaceholder =>
      'Drawer banner · purpose pending (G-06)';

  @override
  String get readerBookmark => 'Bookmark page';

  @override
  String get readerTranslation => 'Translation';

  @override
  String get readerIndex => 'Index';

  @override
  String get readerAutoScroll => 'Auto-scroll';

  @override
  String get moreOptions => 'More options';

  @override
  String get menuSearch => 'Search';

  @override
  String get menuControls => 'Controls';

  @override
  String get menuGoToPage => 'Go To Page';

  @override
  String get menuLightMode => 'Light mode';

  @override
  String get menuDarkMode => 'Dark mode';

  @override
  String get ayahPlay => 'Play';

  @override
  String get ayahToEndOfSura => 'to the end of sura';

  @override
  String get ayahTafsir => 'Tafsir';

  @override
  String get ayahRecitationPlusTafsir => 'Recitation + Tafsir';

  @override
  String get ayahAddNote => 'Add Note';

  @override
  String get ayahAddItqan => 'Add Itqan';

  @override
  String get ayahBookmark => 'Bookmark';

  @override
  String get ayahCopy => 'Copy';

  @override
  String get ayahShare => 'Share';

  @override
  String get quranTextPendingTitle => 'Layout preview · not Quran text';

  @override
  String get quranTextPendingBody =>
      'Sheekh Calinuur shows only verified Quran text. The verified source is still being prepared, so these hatched blocks only mark where the text will go.';

  @override
  String get surahHeaderPlaceholder => 'Surah header ornament · asset needed';

  @override
  String placeholderAyahSemantics(int index) {
    return 'Placeholder ayah $index. Not Quran text. Long press to open ayah actions.';
  }

  @override
  String get unavailableQuranText =>
      'Not available yet: verified Quran text hasn\'t been imported.';

  @override
  String get unavailableFeature =>
      'Not available yet: this arrives in a later phase.';

  @override
  String get unavailableNoMapping =>
      'Not available: no verified Sheikh recording is linked to this ayah.';

  @override
  String get comingSoonTitle => 'Coming in a later phase';

  @override
  String get comingSoonBody =>
      'This section hasn\'t been built yet. Nothing is shown here until real, verified content exists.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get settingsReaderTheme => 'Reading theme';

  @override
  String get readerThemeDark => 'Dark';

  @override
  String get readerThemeLight => 'Light';

  @override
  String get tabSurah => 'Surah';

  @override
  String get tabJuz => 'Juz';

  @override
  String get indexSearchHint => 'Search by name or number';

  @override
  String get indexUnavailableTitle => 'Surah and juz index not available yet';

  @override
  String get indexUnavailableBody =>
      'The index lists only verified Quran metadata: surah names, ayah counts and juz boundaries. The verified source is still being prepared, so nothing is listed yet. The rows below only preview the layout.';

  @override
  String get layoutPreviewLabel => 'Layout preview · not real data';

  @override
  String get revelationMakki => 'Makki';

  @override
  String get revelationMadani => 'Madani';

  @override
  String ayahCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return '$_temp0';
  }

  @override
  String juzTitle(String number) {
    return 'Juz $number';
  }

  @override
  String juzStartsAt(String surah, String reference) {
    return 'Starts at $surah $reference';
  }

  @override
  String get noSearchResults => 'No matches';

  @override
  String surahRowSemantics(String number, String name, String details) {
    return 'Surah $number, $name. $details';
  }

  @override
  String get librarySearchHint => 'Search titles and authors';

  @override
  String get categoryAll => 'All';

  @override
  String get categorySheikh => 'Sheikh\'s books';

  @override
  String get categoryTafsir => 'Tafsir';

  @override
  String get categoryHadith => 'Hadith';

  @override
  String get categoryFiqh => 'Fiqh';

  @override
  String get categoryAqeedah => 'Aqeedah';

  @override
  String get categorySeerah => 'Seerah';

  @override
  String get categoryHistory => 'Islamic History';

  @override
  String get categoryArabic => 'Arabic Language';

  @override
  String get categoryQuranSciences => 'Quran Sciences';

  @override
  String get categoryEducation => 'Islamic Education';

  @override
  String get categoryOther => 'Other';

  @override
  String get sectionSheikhBooks => 'Sheikh Calinuur\'s books';

  @override
  String get sectionAllBooks => 'All books';

  @override
  String get libraryEmptyTitle => 'No books yet';

  @override
  String get libraryEmptyBody =>
      'Books appear here once they\'ve been imported, verified and published. Nothing is shown before that.';

  @override
  String get libraryNoResults => 'No books match your search';

  @override
  String get libraryLoadError => 'The library couldn\'t be loaded.';

  @override
  String get retry => 'Try again';

  @override
  String get previewBanner => 'Design preview data · not real books';

  @override
  String get previewBadge => 'Preview';

  @override
  String get badgeAudio => 'Audio';

  @override
  String get badgeTranscript => 'Transcript';

  @override
  String get badgeSynced => 'Synced';

  @override
  String get badgeDownloaded => 'Downloaded';

  @override
  String get badgeNoTranscript => 'No transcript';

  @override
  String get badgeNotSynced => 'Not synced';

  @override
  String get badgeNeedsVerification => 'Needs verification';

  @override
  String get notRecorded => 'Not recorded';

  @override
  String get fieldAuthor => 'Author';

  @override
  String get fieldEdition => 'Edition';

  @override
  String get fieldPublisher => 'Publisher';

  @override
  String get fieldLanguage => 'Language';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldVolumes => 'Volumes';

  @override
  String get fieldPages => 'Pages';

  @override
  String get langNameArabic => 'Arabic';

  @override
  String get langNameSomali => 'Somali';

  @override
  String get langNameEnglish => 'English';

  @override
  String get actionRead => 'Read';

  @override
  String get actionDownload => 'Download';

  @override
  String get sectionContents => 'Volumes & chapters';

  @override
  String volumeTitle(String number) {
    return 'Volume $number';
  }

  @override
  String chapterTitle(String number) {
    return 'Chapter $number';
  }

  @override
  String lessonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons',
      one: '1 lesson',
      zero: 'No lessons',
    );
    return '$_temp0';
  }

  @override
  String get sectionRights => 'Rights & source';

  @override
  String get rightsNotRecorded =>
      'No rights evidence recorded yet (P-22). The book stays unpublished until it is.';

  @override
  String get bookNotFound => 'This book isn\'t available.';

  @override
  String coverSemantics(String title) {
    return 'Cover of $title';
  }

  @override
  String get back => 'Back';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionHijri => 'Hijri date';

  @override
  String get hijriMethod => 'Calculation method';

  @override
  String get hijriMethodUmmAlQura => 'Umm al-Qura (provisional)';

  @override
  String get hijriAdjustment => 'Adjustment';

  @override
  String get hijriAdjustmentHint =>
      'Move the date if your local moon sighting differs.';

  @override
  String hijriAdjustmentSemantics(String value) {
    return 'Adjust the Hijri date by $value days';
  }

  @override
  String hijriToday(String date) {
    return 'Today: $date';
  }

  @override
  String get settingsSectionDownloads => 'Downloads';

  @override
  String get wifiOnly => 'Download on Wi-Fi only';

  @override
  String get wifiOnlyHint => 'Applies once downloads are available.';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get contentSources => 'Content sources & licences';

  @override
  String get aboutApp => 'About Sheekh Calinuur';

  @override
  String get settingsSectionDeveloper => 'Developer · debug builds only';

  @override
  String get designPreview => 'Design preview data';

  @override
  String get designPreviewHint =>
      'Shows clearly labelled placeholder books so the screens can be reviewed. Never available in release builds.';

  @override
  String get sourceQuranText => 'Quran text';

  @override
  String get sourceQuranMetadata => 'Surah and juz index';

  @override
  String get sourceNotInstalled =>
      'Not installed yet · source awaiting approval';

  @override
  String get sourceTranslation => 'Translation of meanings';

  @override
  String get sourceBooks => 'Books, Tafsir and lessons';

  @override
  String get sourceBooksStatus => 'None published yet';

  @override
  String get sourceFonts => 'Fonts';

  @override
  String get sourceFontsStatus =>
      'Amiri (Quran text), Inter, Noto Sans Arabic, Noto Naskh Arabic · SIL Open Font License 1.1';

  @override
  String get sourceHijri => 'Hijri calendar';

  @override
  String get sourceHijriStatus =>
      'Umm al-Qura table (hijri package, BSD-2-Clause) · provisional';

  @override
  String get openLicences => 'Open-source licences';

  @override
  String get rightsRecordedText => 'Rights evidence recorded.';

  @override
  String surahMeta(String revelation, String ayahs) {
    return '$revelation · $ayahs';
  }

  @override
  String quranSourceLine(String version) {
    return 'Quran text: Tanzil Uthmani $version · tanzil.net';
  }

  @override
  String get reviewPending => 'Reviewer check pending';

  @override
  String reviewDone(String name, String date) {
    return 'Checked by $name · $date';
  }

  @override
  String get sourceDialogTitle => 'About this Quran text';

  @override
  String get sourceLabel => 'Source';

  @override
  String sourceValue(String name, String script, String version) {
    return '$name, $script script, version $version';
  }

  @override
  String get linkLabel => 'Link';

  @override
  String get numberingLabel => 'Numbering';

  @override
  String get numberingHafsBasmala =>
      'Hafs (Kufan count), as in the source. The basmala is ayah 1 of Al-Fatiha.';

  @override
  String get checksLabel => 'Checks';

  @override
  String get checksText =>
      'Whole source file validated (6,236 ayahs); every ayah checksum re-verified when loaded; letter-for-letter match with an independent source.';

  @override
  String get reviewLabel => 'Reviewer check';

  @override
  String get licenceLabel => 'Licence (verbatim)';

  @override
  String get copyLink => 'Copy link';

  @override
  String get linkCopied => 'Link copied';

  @override
  String ayahReference(String surah, String surahNumber, String ayah) {
    return '$surah $surahNumber:$ayah';
  }

  @override
  String copiedAyah(String reference) {
    return 'Copied $reference';
  }

  @override
  String quranAyahSemantics(String number) {
    return 'Ayah $number';
  }

  @override
  String get unavailableRecitation => 'No recitation audio yet.';

  @override
  String get unavailableTafsirText =>
      'The written Tafsir for this ayah hasn\'t been supplied yet.';

  @override
  String get unavailableTranslation => 'No approved translation yet.';

  @override
  String get unavailableRecording =>
      'The Sheikh\'s recording isn\'t available on this device.';

  @override
  String get tafsirBadge => 'Sheikh\'s Tafsir · original recording';

  @override
  String get notRecitation => 'Explanation, not Quran recitation';

  @override
  String get tafsirTitle => 'Tafsir of Al-Fatiha';

  @override
  String get speakerName => 'Sheikh Calinuur';

  @override
  String get testingOnly => 'Testing only · not for distribution';

  @override
  String get recordingNotInstalled =>
      'The Sheikh\'s Tafsir recording isn\'t installed on this device.';

  @override
  String get recordingInstallHint =>
      'Testing only: install the original file as described in the review guide.';

  @override
  String get recordingMismatch =>
      'This file isn\'t the original recording, so it won\'t be played.';

  @override
  String get playerPlay => 'Play';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerReplay => 'Play again';

  @override
  String get playerBack10 => 'Back 10 seconds';

  @override
  String get playerForward10 => 'Forward 10 seconds';

  @override
  String get playerPosition => 'Playback position';

  @override
  String get playerError => 'The recording couldn\'t be played.';

  @override
  String get playerLoading => 'Loading…';

  @override
  String get syncPending => 'Ayah highlighting: waiting for review';

  @override
  String syncFollowing(String ayahs, String kind) {
    return 'Ayah $ayahs · $kind';
  }

  @override
  String get kindReading => 'recitation';

  @override
  String get kindExplanation => 'explaining';

  @override
  String get syncGap => 'No reviewed passage at this point';

  @override
  String get syncMismatch => 'The mapping belongs to a different recording';

  @override
  String get syncInvalid => 'The mapping has errors and is switched off';

  @override
  String get sourceQuranTextFatiha =>
      'Al-Fatiha installed · Tanzil Uthmani 1.1, verbatim · reviewer check pending';

  @override
  String noReviewedExplanation(String number) {
    return 'Ayah $number has no reviewed explanation yet.';
  }

  @override
  String syncFollowingRange(String ayahs, String kind, String range) {
    return 'Ayah $ayahs · $kind · $range';
  }

  @override
  String syncSelectedNoExplanation(String number) {
    return 'Ayah $number: no reviewed explanation yet';
  }

  @override
  String syncLoadingAyah(String number) {
    return 'Ayah $number · starting explanation…';
  }

  @override
  String syncIntro(String range) {
    return 'Introduction · $range';
  }

  @override
  String syncQa(String range) {
    return 'Questions and answers · $range';
  }

  @override
  String get recordingPhoneOnly =>
      'The Sheikh\'s recording plays only in the Android and iOS app. It is a testing-only file and is not part of the web version.';

  @override
  String syncCandidate(String ayahs, String range, String confidence) {
    return 'Unreviewed AI candidate · Ayah $ayahs · $range · $confidence confidence · not verified';
  }

  @override
  String syncSegmentFinished(String number) {
    return 'Ayah $number: end of this segment · tap the ayah to hear it again';
  }

  @override
  String get confidenceHigh => 'high';

  @override
  String get confidenceMedium => 'medium';

  @override
  String get confidenceLow => 'low';

  @override
  String get autoScrollOn => 'Auto-scroll on · tap the text to stop';

  @override
  String get autoScrollStop => 'Stop auto-scroll';

  @override
  String get noTafsirForSurah =>
      'The Sheikh\'s Tafsir recording is available for Al-Fatiha only, so far.';

  @override
  String get bookmarkAdded => 'Bookmark added';

  @override
  String get bookmarkRemoved => 'Bookmark removed';

  @override
  String get ayahRemoveBookmark => 'Remove bookmark';

  @override
  String get tabBookmarks => 'Bookmarks';

  @override
  String get bookmarksEmptyTitle => 'No bookmarks yet';

  @override
  String get bookmarksEmptyBody =>
      'Long-press an ayah in the reader and choose Bookmark. Bookmarks are kept on this device.';

  @override
  String bookmarkAyahLine(String reference) {
    return 'Ayah $reference';
  }

  @override
  String get readingControls => 'Reading controls';

  @override
  String get readerDarkPage => 'Dark reading page';

  @override
  String textSizeValue(String size) {
    return 'Quran text size: $size';
  }

  @override
  String get quranTextSize => 'Quran text size';

  @override
  String get textSmaller => 'Smaller text';

  @override
  String get textLarger => 'Larger text';

  @override
  String get textSizeReset => 'Reset';

  @override
  String get previousSurah => 'Previous surah';

  @override
  String get nextSurah => 'Next surah';

  @override
  String get quranSearchTitle => 'Search the Quran';

  @override
  String get quranSearchHint => 'Search Arabic text (marks are optional)';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get quranSearchMinChars =>
      'Type at least two Arabic letters. Harakat and other marks are ignored while matching; the text is always shown exactly as in the source.';

  @override
  String quranSearchResults(String count) {
    return '$count ayahs';
  }

  @override
  String quranSearchManyResults(String count) {
    return 'First $count ayahs · refine the search for fewer';
  }

  @override
  String quranSearchSkipped(String count) {
    return '$count surahs failed verification and were not searched';
  }

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutQuranBody =>
      'All 114 surahs from Tanzil Uthmani 1.1, shown verbatim. Every ayah is checked against its recorded checksum when it loads and was cross-checked letter by letter against a second source. A reader\'s on-device check is still pending.';

  @override
  String get aboutTafsirTitle => 'Sheikh Calinuur\'s Tafsir';

  @override
  String get aboutTafsirBody =>
      'The Sheikh\'s recorded Tafsir of Al-Fatiha, for testing builds only until distribution rights are confirmed. Ayah segments are being reviewed; unreviewed ones are clearly labelled.';

  @override
  String get aboutPrivacyTitle => 'Privacy';

  @override
  String get aboutPrivacyBody =>
      'No account and no tracking. Settings, bookmarks and your reading place stay on this device.';

  @override
  String get openSourceLicences => 'Open-source licences';

  @override
  String get sourceQuranTextStatus =>
      'All 114 surahs · Tanzil Uthmani 1.1, verbatim · cross-checked with a second source · reviewer check pending';

  @override
  String get sourceQuranMetadataStatus =>
      'Tanzil metadata 1.0 · 114 surahs, 30 juz · cross-checked with a second source';

  @override
  String get logoSemantics => 'Sheekh Calinuur logo';
}
