import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Official product name (C-02). The Arabic form is pending owner confirmation (P-19), so both locales use the Latin form.
  ///
  /// In en, this message translates to:
  /// **'Sheekh Calinuur'**
  String get appName;

  /// Official tagline from the master prompt §2 branding.
  ///
  /// In en, this message translates to:
  /// **'Islamic Digital Learning Platform'**
  String get appTagline;

  /// No description provided for @splashPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing your library…'**
  String get splashPreparing;

  /// No description provided for @hijriDate.
  ///
  /// In en, this message translates to:
  /// **'{day} {month} {year} AH'**
  String hijriDate(String day, String month, String year);

  /// No description provided for @gregorianSuffix.
  ///
  /// In en, this message translates to:
  /// **'CE'**
  String get gregorianSuffix;

  /// No description provided for @hijriMonth1.
  ///
  /// In en, this message translates to:
  /// **'Muharram'**
  String get hijriMonth1;

  /// No description provided for @hijriMonth2.
  ///
  /// In en, this message translates to:
  /// **'Safar'**
  String get hijriMonth2;

  /// No description provided for @hijriMonth3.
  ///
  /// In en, this message translates to:
  /// **'Rabi al-Awwal'**
  String get hijriMonth3;

  /// No description provided for @hijriMonth4.
  ///
  /// In en, this message translates to:
  /// **'Rabi al-Thani'**
  String get hijriMonth4;

  /// No description provided for @hijriMonth5.
  ///
  /// In en, this message translates to:
  /// **'Jumada al-Awwal'**
  String get hijriMonth5;

  /// No description provided for @hijriMonth6.
  ///
  /// In en, this message translates to:
  /// **'Jumada al-Thani'**
  String get hijriMonth6;

  /// No description provided for @hijriMonth7.
  ///
  /// In en, this message translates to:
  /// **'Rajab'**
  String get hijriMonth7;

  /// No description provided for @hijriMonth8.
  ///
  /// In en, this message translates to:
  /// **'Shaban'**
  String get hijriMonth8;

  /// No description provided for @hijriMonth9.
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get hijriMonth9;

  /// No description provided for @hijriMonth10.
  ///
  /// In en, this message translates to:
  /// **'Shawwal'**
  String get hijriMonth10;

  /// No description provided for @hijriMonth11.
  ///
  /// In en, this message translates to:
  /// **'Dhu al-Qadah'**
  String get hijriMonth11;

  /// No description provided for @hijriMonth12.
  ///
  /// In en, this message translates to:
  /// **'Dhu al-Hijjah'**
  String get hijriMonth12;

  /// No description provided for @openMenu.
  ///
  /// In en, this message translates to:
  /// **'Open navigation menu'**
  String get openMenu;

  /// No description provided for @dhikrOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Dhikr of the Day'**
  String get dhikrOfTheDay;

  /// No description provided for @placeholderDhikrArabic.
  ///
  /// In en, this message translates to:
  /// **'Verified Arabic dhikr text · source pending (P-12)'**
  String get placeholderDhikrArabic;

  /// No description provided for @placeholderDhikrTranslation.
  ///
  /// In en, this message translates to:
  /// **'Named translation · pending (P-12)'**
  String get placeholderDhikrTranslation;

  /// No description provided for @placeholderDhikrReference.
  ///
  /// In en, this message translates to:
  /// **'Reference line: collection and number (DV-03)'**
  String get placeholderDhikrReference;

  /// No description provided for @placeholderPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo placeholder · rights needed'**
  String get placeholderPhoto;

  /// No description provided for @placeholderLogo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get placeholderLogo;

  /// No description provided for @placeholderIllustration.
  ///
  /// In en, this message translates to:
  /// **'Illustration'**
  String get placeholderIllustration;

  /// No description provided for @placeholderSemantics.
  ///
  /// In en, this message translates to:
  /// **'Placeholder: {label}'**
  String placeholderSemantics(String label);

  /// No description provided for @quranCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quranCardTitle;

  /// No description provided for @quranCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read, Listen, Tafsir & Explore'**
  String get quranCardSubtitle;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @khatmahTitle.
  ///
  /// In en, this message translates to:
  /// **'Khatmah'**
  String get khatmahTitle;

  /// No description provided for @khatmahSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete the Quran · Individual & Team'**
  String get khatmahSubtitle;

  /// No description provided for @prayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times & Qibla'**
  String get prayerTitle;

  /// No description provided for @prayerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adhan times · Qibla direction'**
  String get prayerSubtitle;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @librarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Islamic books · Read offline'**
  String get librarySubtitle;

  /// No description provided for @lessonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sheikh\'s Lessons'**
  String get lessonsTitle;

  /// No description provided for @lessonsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Original recordings · Listen & follow'**
  String get lessonsSubtitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navLessons.
  ///
  /// In en, this message translates to:
  /// **'Sheikh\'s Lessons'**
  String get navLessons;

  /// No description provided for @navTafsir.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get navTafsir;

  /// No description provided for @navDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get navDownloads;

  /// No description provided for @navRecentPage.
  ///
  /// In en, this message translates to:
  /// **'Recent Page'**
  String get navRecentPage;

  /// No description provided for @navIndexBookmark.
  ///
  /// In en, this message translates to:
  /// **'Index & Bookmark'**
  String get navIndexBookmark;

  /// No description provided for @navMyNotes.
  ///
  /// In en, this message translates to:
  /// **'My Notes'**
  String get navMyNotes;

  /// No description provided for @navItqan.
  ///
  /// In en, this message translates to:
  /// **'Itqan'**
  String get navItqan;

  /// No description provided for @navStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get navStatistics;

  /// No description provided for @navRecitationCorrection.
  ///
  /// In en, this message translates to:
  /// **'Recitation Correction'**
  String get navRecitationCorrection;

  /// No description provided for @navLearnHowToUse.
  ///
  /// In en, this message translates to:
  /// **'Learn How to Use!'**
  String get navLearnHowToUse;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get navAbout;

  /// No description provided for @navLiveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get navLiveChat;

  /// No description provided for @drawerBannerPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Drawer banner · purpose pending (G-06)'**
  String get drawerBannerPlaceholder;

  /// No description provided for @readerBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark page'**
  String get readerBookmark;

  /// No description provided for @readerTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get readerTranslation;

  /// No description provided for @readerIndex.
  ///
  /// In en, this message translates to:
  /// **'Index'**
  String get readerIndex;

  /// No description provided for @readerAutoScroll.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll'**
  String get readerAutoScroll;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @menuSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get menuSearch;

  /// No description provided for @menuControls.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get menuControls;

  /// No description provided for @menuGoToPage.
  ///
  /// In en, this message translates to:
  /// **'Go To Page'**
  String get menuGoToPage;

  /// No description provided for @menuLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get menuLightMode;

  /// No description provided for @menuDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get menuDarkMode;

  /// No description provided for @ayahPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get ayahPlay;

  /// No description provided for @ayahToEndOfSura.
  ///
  /// In en, this message translates to:
  /// **'to the end of sura'**
  String get ayahToEndOfSura;

  /// No description provided for @ayahTafsir.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get ayahTafsir;

  /// No description provided for @ayahRecitationPlusTafsir.
  ///
  /// In en, this message translates to:
  /// **'Recitation + Tafsir'**
  String get ayahRecitationPlusTafsir;

  /// No description provided for @ayahAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get ayahAddNote;

  /// No description provided for @ayahAddItqan.
  ///
  /// In en, this message translates to:
  /// **'Add Itqan'**
  String get ayahAddItqan;

  /// No description provided for @ayahBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get ayahBookmark;

  /// No description provided for @ayahCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get ayahCopy;

  /// No description provided for @ayahShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get ayahShare;

  /// No description provided for @quranTextPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Layout preview · not Quran text'**
  String get quranTextPendingTitle;

  /// No description provided for @quranTextPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Sheekh Calinuur shows only verified Quran text. The verified source is still being prepared, so these hatched blocks only mark where the text will go.'**
  String get quranTextPendingBody;

  /// No description provided for @surahHeaderPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Surah header ornament · asset needed'**
  String get surahHeaderPlaceholder;

  /// No description provided for @placeholderAyahSemantics.
  ///
  /// In en, this message translates to:
  /// **'Placeholder ayah {index}. Not Quran text. Long press to open ayah actions.'**
  String placeholderAyahSemantics(int index);

  /// No description provided for @unavailableQuranText.
  ///
  /// In en, this message translates to:
  /// **'Not available yet: verified Quran text hasn\'t been imported.'**
  String get unavailableQuranText;

  /// No description provided for @unavailableFeature.
  ///
  /// In en, this message translates to:
  /// **'Not available yet: this arrives in a later phase.'**
  String get unavailableFeature;

  /// No description provided for @unavailableNoMapping.
  ///
  /// In en, this message translates to:
  /// **'Not available: no verified Sheikh recording is linked to this ayah.'**
  String get unavailableNoMapping;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming in a later phase'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This section hasn\'t been built yet. Nothing is shown here until real, verified content exists.'**
  String get comingSoonBody;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @settingsReaderTheme.
  ///
  /// In en, this message translates to:
  /// **'Reading theme'**
  String get settingsReaderTheme;

  /// No description provided for @readerThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get readerThemeDark;

  /// No description provided for @readerThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get readerThemeLight;

  /// No description provided for @tabSurah.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get tabSurah;

  /// No description provided for @tabJuz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get tabJuz;

  /// No description provided for @indexSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or number'**
  String get indexSearchHint;

  /// No description provided for @indexUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Surah and juz index not available yet'**
  String get indexUnavailableTitle;

  /// No description provided for @indexUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'The index lists only verified Quran metadata: surah names, ayah counts and juz boundaries. The verified source is still being prepared, so nothing is listed yet. The rows below only preview the layout.'**
  String get indexUnavailableBody;

  /// No description provided for @layoutPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Layout preview · not real data'**
  String get layoutPreviewLabel;

  /// No description provided for @revelationMakki.
  ///
  /// In en, this message translates to:
  /// **'Makki'**
  String get revelationMakki;

  /// No description provided for @revelationMadani.
  ///
  /// In en, this message translates to:
  /// **'Madani'**
  String get revelationMadani;

  /// No description provided for @ayahCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ayah} other{{count} ayahs}}'**
  String ayahCount(int count);

  /// No description provided for @juzTitle.
  ///
  /// In en, this message translates to:
  /// **'Juz {number}'**
  String juzTitle(String number);

  /// No description provided for @juzStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at {surah} {reference}'**
  String juzStartsAt(String surah, String reference);

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noSearchResults;

  /// No description provided for @surahRowSemantics.
  ///
  /// In en, this message translates to:
  /// **'Surah {number}, {name}. {details}'**
  String surahRowSemantics(String number, String name, String details);

  /// No description provided for @librarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search titles and authors'**
  String get librarySearchHint;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categorySheikh.
  ///
  /// In en, this message translates to:
  /// **'Sheikh\'s books'**
  String get categorySheikh;

  /// No description provided for @categoryTafsir.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get categoryTafsir;

  /// No description provided for @categoryHadith.
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get categoryHadith;

  /// No description provided for @categoryFiqh.
  ///
  /// In en, this message translates to:
  /// **'Fiqh'**
  String get categoryFiqh;

  /// No description provided for @categoryAqeedah.
  ///
  /// In en, this message translates to:
  /// **'Aqeedah'**
  String get categoryAqeedah;

  /// No description provided for @categorySeerah.
  ///
  /// In en, this message translates to:
  /// **'Seerah'**
  String get categorySeerah;

  /// No description provided for @categoryHistory.
  ///
  /// In en, this message translates to:
  /// **'Islamic History'**
  String get categoryHistory;

  /// No description provided for @categoryArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic Language'**
  String get categoryArabic;

  /// No description provided for @categoryQuranSciences.
  ///
  /// In en, this message translates to:
  /// **'Quran Sciences'**
  String get categoryQuranSciences;

  /// No description provided for @categoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Islamic Education'**
  String get categoryEducation;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @sectionSheikhBooks.
  ///
  /// In en, this message translates to:
  /// **'Sheikh Calinuur\'s books'**
  String get sectionSheikhBooks;

  /// No description provided for @sectionAllBooks.
  ///
  /// In en, this message translates to:
  /// **'All books'**
  String get sectionAllBooks;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No books yet'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Books appear here once they\'ve been imported, verified and published. Nothing is shown before that.'**
  String get libraryEmptyBody;

  /// No description provided for @libraryNoResults.
  ///
  /// In en, this message translates to:
  /// **'No books match your search'**
  String get libraryNoResults;

  /// No description provided for @libraryLoadError.
  ///
  /// In en, this message translates to:
  /// **'The library couldn\'t be loaded.'**
  String get libraryLoadError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @previewBanner.
  ///
  /// In en, this message translates to:
  /// **'Design preview data · not real books'**
  String get previewBanner;

  /// No description provided for @previewBadge.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewBadge;

  /// No description provided for @badgeAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get badgeAudio;

  /// No description provided for @badgeTranscript.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get badgeTranscript;

  /// No description provided for @badgeSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get badgeSynced;

  /// No description provided for @badgeDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get badgeDownloaded;

  /// No description provided for @badgeNoTranscript.
  ///
  /// In en, this message translates to:
  /// **'No transcript'**
  String get badgeNoTranscript;

  /// No description provided for @badgeNotSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced'**
  String get badgeNotSynced;

  /// No description provided for @badgeNeedsVerification.
  ///
  /// In en, this message translates to:
  /// **'Needs verification'**
  String get badgeNeedsVerification;

  /// No description provided for @notRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get notRecorded;

  /// No description provided for @fieldAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get fieldAuthor;

  /// No description provided for @fieldEdition.
  ///
  /// In en, this message translates to:
  /// **'Edition'**
  String get fieldEdition;

  /// No description provided for @fieldPublisher.
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get fieldPublisher;

  /// No description provided for @fieldLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get fieldLanguage;

  /// No description provided for @fieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// No description provided for @fieldVolumes.
  ///
  /// In en, this message translates to:
  /// **'Volumes'**
  String get fieldVolumes;

  /// No description provided for @fieldPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get fieldPages;

  /// No description provided for @langNameArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get langNameArabic;

  /// No description provided for @langNameSomali.
  ///
  /// In en, this message translates to:
  /// **'Somali'**
  String get langNameSomali;

  /// No description provided for @langNameEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langNameEnglish;

  /// No description provided for @actionRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get actionRead;

  /// No description provided for @actionDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get actionDownload;

  /// No description provided for @sectionContents.
  ///
  /// In en, this message translates to:
  /// **'Volumes & chapters'**
  String get sectionContents;

  /// No description provided for @volumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Volume {number}'**
  String volumeTitle(String number);

  /// No description provided for @chapterTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String chapterTitle(String number);

  /// No description provided for @lessonCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No lessons} =1{1 lesson} other{{count} lessons}}'**
  String lessonCount(int count);

  /// No description provided for @sectionRights.
  ///
  /// In en, this message translates to:
  /// **'Rights & source'**
  String get sectionRights;

  /// No description provided for @rightsNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'No rights evidence recorded yet (P-22). The book stays unpublished until it is.'**
  String get rightsNotRecorded;

  /// No description provided for @bookNotFound.
  ///
  /// In en, this message translates to:
  /// **'This book isn\'t available.'**
  String get bookNotFound;

  /// No description provided for @coverSemantics.
  ///
  /// In en, this message translates to:
  /// **'Cover of {title}'**
  String coverSemantics(String title);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @settingsSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsSectionGeneral;

  /// No description provided for @settingsSectionHijri.
  ///
  /// In en, this message translates to:
  /// **'Hijri date'**
  String get settingsSectionHijri;

  /// No description provided for @hijriMethod.
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get hijriMethod;

  /// No description provided for @hijriMethodUmmAlQura.
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura (provisional)'**
  String get hijriMethodUmmAlQura;

  /// No description provided for @hijriAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get hijriAdjustment;

  /// No description provided for @hijriAdjustmentHint.
  ///
  /// In en, this message translates to:
  /// **'Move the date if your local moon sighting differs.'**
  String get hijriAdjustmentHint;

  /// No description provided for @hijriAdjustmentSemantics.
  ///
  /// In en, this message translates to:
  /// **'Adjust the Hijri date by {value} days'**
  String hijriAdjustmentSemantics(String value);

  /// No description provided for @hijriToday.
  ///
  /// In en, this message translates to:
  /// **'Today: {date}'**
  String hijriToday(String date);

  /// No description provided for @settingsSectionDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get settingsSectionDownloads;

  /// No description provided for @wifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Download on Wi-Fi only'**
  String get wifiOnly;

  /// No description provided for @wifiOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Applies once downloads are available.'**
  String get wifiOnlyHint;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @contentSources.
  ///
  /// In en, this message translates to:
  /// **'Content sources & licences'**
  String get contentSources;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About Sheekh Calinuur'**
  String get aboutApp;

  /// No description provided for @settingsSectionDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer · debug builds only'**
  String get settingsSectionDeveloper;

  /// No description provided for @designPreview.
  ///
  /// In en, this message translates to:
  /// **'Design preview data'**
  String get designPreview;

  /// No description provided for @designPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Shows clearly labelled placeholder books so the screens can be reviewed. Never available in release builds.'**
  String get designPreviewHint;

  /// No description provided for @sourceQuranText.
  ///
  /// In en, this message translates to:
  /// **'Quran text'**
  String get sourceQuranText;

  /// No description provided for @sourceQuranMetadata.
  ///
  /// In en, this message translates to:
  /// **'Surah and juz index'**
  String get sourceQuranMetadata;

  /// No description provided for @sourceNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed yet · source awaiting approval'**
  String get sourceNotInstalled;

  /// No description provided for @sourceTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation of meanings'**
  String get sourceTranslation;

  /// No description provided for @sourceBooks.
  ///
  /// In en, this message translates to:
  /// **'Books, Tafsir and lessons'**
  String get sourceBooks;

  /// No description provided for @sourceBooksStatus.
  ///
  /// In en, this message translates to:
  /// **'None published yet'**
  String get sourceBooksStatus;

  /// No description provided for @sourceFonts.
  ///
  /// In en, this message translates to:
  /// **'Fonts'**
  String get sourceFonts;

  /// No description provided for @sourceFontsStatus.
  ///
  /// In en, this message translates to:
  /// **'Inter, Noto Sans Arabic, Noto Naskh Arabic · SIL Open Font License 1.1'**
  String get sourceFontsStatus;

  /// No description provided for @sourceHijri.
  ///
  /// In en, this message translates to:
  /// **'Hijri calendar'**
  String get sourceHijri;

  /// No description provided for @sourceHijriStatus.
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura table (hijri package, BSD-2-Clause) · provisional'**
  String get sourceHijriStatus;

  /// No description provided for @openLicences.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get openLicences;

  /// No description provided for @rightsRecordedText.
  ///
  /// In en, this message translates to:
  /// **'Rights evidence recorded.'**
  String get rightsRecordedText;

  /// No description provided for @surahMeta.
  ///
  /// In en, this message translates to:
  /// **'{revelation} · {ayahs}'**
  String surahMeta(String revelation, String ayahs);

  /// No description provided for @quranSourceLine.
  ///
  /// In en, this message translates to:
  /// **'Quran text: Tanzil Uthmani {version} · tanzil.net'**
  String quranSourceLine(String version);

  /// No description provided for @reviewPending.
  ///
  /// In en, this message translates to:
  /// **'Reviewer check pending'**
  String get reviewPending;

  /// No description provided for @reviewDone.
  ///
  /// In en, this message translates to:
  /// **'Checked by {name} · {date}'**
  String reviewDone(String name, String date);

  /// No description provided for @sourceDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'About this Quran text'**
  String get sourceDialogTitle;

  /// No description provided for @sourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceLabel;

  /// No description provided for @sourceValue.
  ///
  /// In en, this message translates to:
  /// **'{name}, {script} script, version {version}'**
  String sourceValue(String name, String script, String version);

  /// No description provided for @linkLabel.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get linkLabel;

  /// No description provided for @numberingLabel.
  ///
  /// In en, this message translates to:
  /// **'Numbering'**
  String get numberingLabel;

  /// No description provided for @numberingHafsBasmala.
  ///
  /// In en, this message translates to:
  /// **'Hafs (Kufan count), as in the source. The basmala is ayah 1 of Al-Fatiha.'**
  String get numberingHafsBasmala;

  /// No description provided for @checksLabel.
  ///
  /// In en, this message translates to:
  /// **'Checks'**
  String get checksLabel;

  /// No description provided for @checksText.
  ///
  /// In en, this message translates to:
  /// **'Whole source file validated (6,236 ayahs); every ayah checksum re-verified when loaded; letter-for-letter match with an independent source.'**
  String get checksText;

  /// No description provided for @reviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Reviewer check'**
  String get reviewLabel;

  /// No description provided for @licenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Licence (verbatim)'**
  String get licenceLabel;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @ayahReference.
  ///
  /// In en, this message translates to:
  /// **'{surah} {surahNumber}:{ayah}'**
  String ayahReference(String surah, String surahNumber, String ayah);

  /// No description provided for @copiedAyah.
  ///
  /// In en, this message translates to:
  /// **'Copied {reference}'**
  String copiedAyah(String reference);

  /// No description provided for @quranAyahSemantics.
  ///
  /// In en, this message translates to:
  /// **'Ayah {number}'**
  String quranAyahSemantics(String number);

  /// No description provided for @unavailableRecitation.
  ///
  /// In en, this message translates to:
  /// **'No recitation audio yet.'**
  String get unavailableRecitation;

  /// No description provided for @unavailableTafsirText.
  ///
  /// In en, this message translates to:
  /// **'The written Tafsir for this ayah hasn\'t been supplied yet.'**
  String get unavailableTafsirText;

  /// No description provided for @unavailableTranslation.
  ///
  /// In en, this message translates to:
  /// **'No approved translation yet.'**
  String get unavailableTranslation;

  /// No description provided for @unavailableRecording.
  ///
  /// In en, this message translates to:
  /// **'The Sheikh\'s recording isn\'t available on this device.'**
  String get unavailableRecording;

  /// No description provided for @tafsirBadge.
  ///
  /// In en, this message translates to:
  /// **'Sheikh\'s Tafsir · original recording'**
  String get tafsirBadge;

  /// No description provided for @notRecitation.
  ///
  /// In en, this message translates to:
  /// **'Explanation, not Quran recitation'**
  String get notRecitation;

  /// No description provided for @tafsirTitle.
  ///
  /// In en, this message translates to:
  /// **'Tafsir of Al-Fatiha'**
  String get tafsirTitle;

  /// No description provided for @speakerName.
  ///
  /// In en, this message translates to:
  /// **'Sheikh Calinuur'**
  String get speakerName;

  /// No description provided for @testingOnly.
  ///
  /// In en, this message translates to:
  /// **'Testing only · not for distribution'**
  String get testingOnly;

  /// No description provided for @recordingNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'The Sheikh\'s Tafsir recording isn\'t installed on this device.'**
  String get recordingNotInstalled;

  /// No description provided for @recordingInstallHint.
  ///
  /// In en, this message translates to:
  /// **'Testing only: install the original file as described in the review guide.'**
  String get recordingInstallHint;

  /// No description provided for @recordingMismatch.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t the original recording, so it won\'t be played.'**
  String get recordingMismatch;

  /// No description provided for @playerPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playerPlay;

  /// No description provided for @playerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// No description provided for @playerReplay.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playerReplay;

  /// No description provided for @playerBack10.
  ///
  /// In en, this message translates to:
  /// **'Back 10 seconds'**
  String get playerBack10;

  /// No description provided for @playerForward10.
  ///
  /// In en, this message translates to:
  /// **'Forward 10 seconds'**
  String get playerForward10;

  /// No description provided for @playerPosition.
  ///
  /// In en, this message translates to:
  /// **'Playback position'**
  String get playerPosition;

  /// No description provided for @playerError.
  ///
  /// In en, this message translates to:
  /// **'The recording couldn\'t be played.'**
  String get playerError;

  /// No description provided for @playerLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get playerLoading;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'Ayah highlighting: waiting for review'**
  String get syncPending;

  /// No description provided for @syncFollowing.
  ///
  /// In en, this message translates to:
  /// **'Ayah {ayahs} · {kind}'**
  String syncFollowing(String ayahs, String kind);

  /// No description provided for @kindReading.
  ///
  /// In en, this message translates to:
  /// **'recitation'**
  String get kindReading;

  /// No description provided for @kindExplanation.
  ///
  /// In en, this message translates to:
  /// **'explaining'**
  String get kindExplanation;

  /// No description provided for @syncGap.
  ///
  /// In en, this message translates to:
  /// **'No reviewed passage at this point'**
  String get syncGap;

  /// No description provided for @syncMismatch.
  ///
  /// In en, this message translates to:
  /// **'The mapping belongs to a different recording'**
  String get syncMismatch;

  /// No description provided for @syncInvalid.
  ///
  /// In en, this message translates to:
  /// **'The mapping has errors and is switched off'**
  String get syncInvalid;

  /// No description provided for @sourceQuranTextFatiha.
  ///
  /// In en, this message translates to:
  /// **'Al-Fatiha installed · Tanzil Uthmani 1.1, verbatim · reviewer check pending'**
  String get sourceQuranTextFatiha;

  /// No description provided for @noReviewedExplanation.
  ///
  /// In en, this message translates to:
  /// **'Ayah {number} has no reviewed explanation yet.'**
  String noReviewedExplanation(String number);

  /// No description provided for @syncFollowingRange.
  ///
  /// In en, this message translates to:
  /// **'Ayah {ayahs} · {kind} · {range}'**
  String syncFollowingRange(String ayahs, String kind, String range);

  /// No description provided for @syncSelectedNoExplanation.
  ///
  /// In en, this message translates to:
  /// **'Ayah {number}: no reviewed explanation yet'**
  String syncSelectedNoExplanation(String number);

  /// No description provided for @syncLoadingAyah.
  ///
  /// In en, this message translates to:
  /// **'Ayah {number} · starting explanation…'**
  String syncLoadingAyah(String number);

  /// No description provided for @syncIntro.
  ///
  /// In en, this message translates to:
  /// **'Introduction · {range}'**
  String syncIntro(String range);

  /// No description provided for @syncQa.
  ///
  /// In en, this message translates to:
  /// **'Questions and answers · {range}'**
  String syncQa(String range);

  /// Shown in the web build, where the testing-only recording is not available.
  ///
  /// In en, this message translates to:
  /// **'The Sheikh\'s recording plays only in the Android and iOS app. It is a testing-only file and is not part of the web version.'**
  String get recordingPhoneOnly;

  /// Player line while a tapped ayah plays an AI-suggested segment the reviewer has not approved yet (debug/testing builds only).
  ///
  /// In en, this message translates to:
  /// **'Unreviewed AI candidate · Ayah {ayahs} · {range} · {confidence} confidence · not verified'**
  String syncCandidate(String ayahs, String range, String confidence);

  /// No description provided for @syncSegmentFinished.
  ///
  /// In en, this message translates to:
  /// **'Ayah {number}: end of this segment · tap the ayah to hear it again'**
  String syncSegmentFinished(String number);

  /// No description provided for @confidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'high'**
  String get confidenceHigh;

  /// No description provided for @confidenceMedium.
  ///
  /// In en, this message translates to:
  /// **'medium'**
  String get confidenceMedium;

  /// No description provided for @confidenceLow.
  ///
  /// In en, this message translates to:
  /// **'low'**
  String get confidenceLow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
