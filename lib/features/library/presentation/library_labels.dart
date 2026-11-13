import '../../../l10n/app_localizations.dart';
import '../domain/book.dart';

String categoryLabel(AppLocalizations l10n, BookCategory c) => switch (c) {
  BookCategory.tafsir => l10n.categoryTafsir,
  BookCategory.hadith => l10n.categoryHadith,
  BookCategory.fiqh => l10n.categoryFiqh,
  BookCategory.aqeedah => l10n.categoryAqeedah,
  BookCategory.seerah => l10n.categorySeerah,
  BookCategory.history => l10n.categoryHistory,
  BookCategory.arabicLanguage => l10n.categoryArabic,
  BookCategory.quranSciences => l10n.categoryQuranSciences,
  BookCategory.education => l10n.categoryEducation,
  BookCategory.other => l10n.categoryOther,
};

/// The language name, or the raw code if it isn't one the UI names.
String languageLabel(AppLocalizations l10n, String code) => switch (code) {
  'ar' => l10n.langNameArabic,
  'so' => l10n.langNameSomali,
  'en' => l10n.langNameEnglish,
  _ => code,
};
