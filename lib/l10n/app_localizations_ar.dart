// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Sheekh Calinuur';

  @override
  String get appTagline => 'منصة التعلم الإسلامي الرقمية';

  @override
  String get splashPreparing => 'جارٍ تجهيز مكتبتك…';

  @override
  String hijriDate(String day, String month, String year) {
    return '$day $month $year هـ';
  }

  @override
  String get gregorianSuffix => 'م';

  @override
  String get hijriMonth1 => 'محرم';

  @override
  String get hijriMonth2 => 'صفر';

  @override
  String get hijriMonth3 => 'ربيع الأول';

  @override
  String get hijriMonth4 => 'ربيع الآخر';

  @override
  String get hijriMonth5 => 'جمادى الأولى';

  @override
  String get hijriMonth6 => 'جمادى الآخرة';

  @override
  String get hijriMonth7 => 'رجب';

  @override
  String get hijriMonth8 => 'شعبان';

  @override
  String get hijriMonth9 => 'رمضان';

  @override
  String get hijriMonth10 => 'شوال';

  @override
  String get hijriMonth11 => 'ذو القعدة';

  @override
  String get hijriMonth12 => 'ذو الحجة';

  @override
  String get openMenu => 'فتح قائمة التنقل';

  @override
  String get dhikrOfTheDay => 'ذكر اليوم';

  @override
  String get placeholderDhikrArabic =>
      'نص الذكر الموثق · المصدر قيد الاعتماد (P-12)';

  @override
  String get placeholderDhikrTranslation =>
      'ترجمة منسوبة · قيد الاعتماد (P-12)';

  @override
  String get placeholderDhikrReference => 'سطر المرجع: الكتاب والرقم (DV-03)';

  @override
  String get placeholderPhoto => 'عنصر نائب لصورة · يلزم إذن الاستخدام';

  @override
  String get placeholderLogo => 'الشعار';

  @override
  String get placeholderIllustration => 'رسم توضيحي';

  @override
  String placeholderSemantics(String label) {
    return 'عنصر نائب: $label';
  }

  @override
  String get quranCardTitle => 'القرآن الكريم';

  @override
  String get quranCardSubtitle => 'قراءة، استماع، تفسير واستكشاف';

  @override
  String get explore => 'استكشف';

  @override
  String get khatmahTitle => 'الختمة';

  @override
  String get khatmahSubtitle => 'ختم القرآن · فردي وجماعي';

  @override
  String get prayerTitle => 'مواقيت الصلاة والقبلة';

  @override
  String get prayerSubtitle => 'أوقات الأذان · اتجاه القبلة';

  @override
  String get libraryTitle => 'المكتبة';

  @override
  String get librarySubtitle => 'كتب إسلامية · قراءة دون اتصال';

  @override
  String get lessonsTitle => 'دروس الشيخ';

  @override
  String get lessonsSubtitle => 'تسجيلات أصلية · استماع ومتابعة';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navLibrary => 'المكتبة';

  @override
  String get navLessons => 'دروس الشيخ';

  @override
  String get navTafsir => 'التفسير';

  @override
  String get navDownloads => 'التنزيلات';

  @override
  String get navRecentPage => 'الصفحة الأخيرة';

  @override
  String get navIndexBookmark => 'الفهرس والعلامات';

  @override
  String get navMyNotes => 'ملاحظاتي';

  @override
  String get navItqan => 'الإتقان';

  @override
  String get navStatistics => 'الإحصائيات';

  @override
  String get navRecitationCorrection => 'تصحيح التلاوة';

  @override
  String get navLearnHowToUse => 'تعلّم طريقة الاستخدام';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get navAbout => 'حول التطبيق';

  @override
  String get navLiveChat => 'المحادثة المباشرة';

  @override
  String get drawerBannerPlaceholder =>
      'لافتة القائمة · الغرض قيد التحديد (G-06)';

  @override
  String get readerBookmark => 'إضافة علامة للصفحة';

  @override
  String get readerTranslation => 'الترجمة';

  @override
  String get readerIndex => 'الفهرس';

  @override
  String get readerAutoScroll => 'التمرير التلقائي';

  @override
  String get moreOptions => 'خيارات إضافية';

  @override
  String get menuSearch => 'بحث';

  @override
  String get menuControls => 'عناصر التحكم';

  @override
  String get menuGoToPage => 'الانتقال إلى صفحة';

  @override
  String get menuLightMode => 'الوضع الفاتح';

  @override
  String get menuDarkMode => 'الوضع الداكن';

  @override
  String get ayahPlay => 'تشغيل';

  @override
  String get ayahToEndOfSura => 'حتى نهاية السورة';

  @override
  String get ayahTafsir => 'التفسير';

  @override
  String get ayahRecitationPlusTafsir => 'التلاوة + التفسير';

  @override
  String get ayahAddNote => 'إضافة ملاحظة';

  @override
  String get ayahAddItqan => 'إضافة إلى الإتقان';

  @override
  String get ayahBookmark => 'علامة مرجعية';

  @override
  String get ayahCopy => 'نسخ';

  @override
  String get ayahShare => 'مشاركة';

  @override
  String get quranTextPendingTitle => 'معاينة التخطيط · ليس نص القرآن';

  @override
  String get quranTextPendingBody =>
      'لا يعرض التطبيق إلا نص القرآن الموثق. ما زال المصدر الموثق قيد الإعداد، لذا تشير هذه المربعات المظللة فقط إلى موضع النص.';

  @override
  String get surahHeaderPlaceholder => 'زخرفة عنوان السورة · يلزم الملف';

  @override
  String placeholderAyahSemantics(int index) {
    return 'آية نائبة $index. ليست نص القرآن. اضغط مطولًا لفتح خيارات الآية.';
  }

  @override
  String get unavailableQuranText =>
      'غير متاح بعد: لم يتم استيراد نص القرآن الموثق.';

  @override
  String get unavailableFeature =>
      'غير متاح بعد: تتوفر هذه الميزة في مرحلة لاحقة.';

  @override
  String get unavailableNoMapping =>
      'غير متاح: لا يوجد تسجيل موثق للشيخ مرتبط بهذه الآية.';

  @override
  String get comingSoonTitle => 'قادم في مرحلة لاحقة';

  @override
  String get comingSoonBody =>
      'لم يُبنَ هذا القسم بعد. لن يُعرض هنا شيء حتى يتوفر محتوى حقيقي وموثق.';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get languageSystem => 'لغة النظام';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get settingsReaderTheme => 'مظهر القراءة';

  @override
  String get readerThemeDark => 'داكن';

  @override
  String get readerThemeLight => 'فاتح';

  @override
  String get tabSurah => 'السور';

  @override
  String get tabJuz => 'الأجزاء';

  @override
  String get indexSearchHint => 'ابحث بالاسم أو الرقم';

  @override
  String get indexUnavailableTitle => 'فهرس السور والأجزاء غير متاح بعد';

  @override
  String get indexUnavailableBody =>
      'لا يعرض الفهرس إلا بيانات القرآن الموثقة: أسماء السور وعدد الآيات وحدود الأجزاء. ما زال المصدر الموثق قيد الإعداد، لذا لا يُعرض شيء بعد. الصفوف أدناه معاينة للتخطيط فقط.';

  @override
  String get layoutPreviewLabel => 'معاينة التخطيط · ليست بيانات حقيقية';

  @override
  String get revelationMakki => 'مكية';

  @override
  String get revelationMadani => 'مدنية';

  @override
  String ayahCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count آية',
      many: '$count آية',
      few: '$count آيات',
      two: 'آيتان',
      one: 'آية واحدة',
      zero: 'لا آيات',
    );
    return '$_temp0';
  }

  @override
  String juzTitle(String number) {
    return 'الجزء $number';
  }

  @override
  String juzStartsAt(String surah, String reference) {
    return 'يبدأ من $surah $reference';
  }

  @override
  String get noSearchResults => 'لا توجد نتائج';

  @override
  String surahRowSemantics(String number, String name, String details) {
    return 'السورة $number، $name. $details';
  }

  @override
  String get librarySearchHint => 'ابحث في العناوين والمؤلفين';

  @override
  String get categoryAll => 'الكل';

  @override
  String get categorySheikh => 'كتب الشيخ';

  @override
  String get categoryTafsir => 'التفسير';

  @override
  String get categoryHadith => 'الحديث';

  @override
  String get categoryFiqh => 'الفقه';

  @override
  String get categoryAqeedah => 'العقيدة';

  @override
  String get categorySeerah => 'السيرة';

  @override
  String get categoryHistory => 'التاريخ الإسلامي';

  @override
  String get categoryArabic => 'اللغة العربية';

  @override
  String get categoryQuranSciences => 'علوم القرآن';

  @override
  String get categoryEducation => 'التربية الإسلامية';

  @override
  String get categoryOther => 'أخرى';

  @override
  String get sectionSheikhBooks => 'كتب الشيخ';

  @override
  String get sectionAllBooks => 'جميع الكتب';

  @override
  String get libraryEmptyTitle => 'لا توجد كتب بعد';

  @override
  String get libraryEmptyBody =>
      'تظهر الكتب هنا بعد استيرادها والتحقق منها ونشرها. لا يُعرض شيء قبل ذلك.';

  @override
  String get libraryNoResults => 'لا توجد كتب مطابقة لبحثك';

  @override
  String get libraryLoadError => 'تعذّر تحميل المكتبة.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get previewBanner => 'بيانات معاينة التصميم · ليست كتبًا حقيقية';

  @override
  String get previewBadge => 'معاينة';

  @override
  String get badgeAudio => 'صوت';

  @override
  String get badgeTranscript => 'تفريغ';

  @override
  String get badgeSynced => 'متزامن';

  @override
  String get badgeDownloaded => 'منزّل';

  @override
  String get badgeNoTranscript => 'بدون تفريغ';

  @override
  String get badgeNotSynced => 'غير متزامن';

  @override
  String get badgeNeedsVerification => 'بحاجة إلى تحقق';

  @override
  String get notRecorded => 'غير مسجل';

  @override
  String get fieldAuthor => 'المؤلف';

  @override
  String get fieldEdition => 'الطبعة';

  @override
  String get fieldPublisher => 'الناشر';

  @override
  String get fieldLanguage => 'اللغة';

  @override
  String get fieldCategory => 'التصنيف';

  @override
  String get fieldVolumes => 'المجلدات';

  @override
  String get fieldPages => 'الصفحات';

  @override
  String get langNameArabic => 'العربية';

  @override
  String get langNameSomali => 'الصومالية';

  @override
  String get langNameEnglish => 'الإنجليزية';

  @override
  String get actionRead => 'قراءة';

  @override
  String get actionDownload => 'تنزيل';

  @override
  String get sectionContents => 'المجلدات والفصول';

  @override
  String volumeTitle(String number) {
    return 'المجلد $number';
  }

  @override
  String chapterTitle(String number) {
    return 'الفصل $number';
  }

  @override
  String lessonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count درس',
      many: '$count درسًا',
      few: '$count دروس',
      two: 'درسان',
      one: 'درس واحد',
      zero: 'لا دروس',
    );
    return '$_temp0';
  }

  @override
  String get sectionRights => 'الحقوق والمصدر';

  @override
  String get rightsNotRecorded =>
      'لم تُسجل أدلة الحقوق بعد (P-22). يبقى الكتاب غير منشور حتى تُسجل.';

  @override
  String get bookNotFound => 'هذا الكتاب غير متاح.';

  @override
  String coverSemantics(String title) {
    return 'غلاف $title';
  }

  @override
  String get back => 'رجوع';

  @override
  String get settingsSectionGeneral => 'عام';

  @override
  String get settingsSectionHijri => 'التاريخ الهجري';

  @override
  String get hijriMethod => 'طريقة الحساب';

  @override
  String get hijriMethodUmmAlQura => 'أم القرى (مؤقتًا)';

  @override
  String get hijriAdjustment => 'التعديل';

  @override
  String get hijriAdjustmentHint =>
      'عدّل التاريخ إذا اختلفت رؤية الهلال في بلدك.';

  @override
  String hijriAdjustmentSemantics(String value) {
    return 'تعديل التاريخ الهجري بمقدار $value يوم';
  }

  @override
  String hijriToday(String date) {
    return 'اليوم: $date';
  }

  @override
  String get settingsSectionDownloads => 'التنزيلات';

  @override
  String get wifiOnly => 'التنزيل عبر Wi-Fi فقط';

  @override
  String get wifiOnlyHint => 'يُطبَّق عند توفر التنزيلات.';

  @override
  String get settingsSectionAbout => 'حول';

  @override
  String get contentSources => 'مصادر المحتوى والتراخيص';

  @override
  String get aboutApp => 'حول Sheekh Calinuur';

  @override
  String get settingsSectionDeveloper => 'المطور · نسخ التطوير فقط';

  @override
  String get designPreview => 'بيانات معاينة التصميم';

  @override
  String get designPreviewHint =>
      'يعرض كتبًا نائبة موسومة بوضوح لمراجعة الشاشات. غير متاح أبدًا في النسخ النهائية.';

  @override
  String get sourceQuranText => 'نص القرآن';

  @override
  String get sourceQuranMetadata => 'فهرس السور والأجزاء';

  @override
  String get sourceNotInstalled => 'غير مثبت بعد · المصدر بانتظار الاعتماد';

  @override
  String get sourceTranslation => 'ترجمة المعاني';

  @override
  String get sourceBooks => 'الكتب والتفسير والدروس';

  @override
  String get sourceBooksStatus => 'لم يُنشر شيء بعد';

  @override
  String get sourceFonts => 'الخطوط';

  @override
  String get sourceFontsStatus =>
      'أميري (نص القرآن)، Inter، Noto Sans Arabic، Noto Naskh Arabic · رخصة SIL المفتوحة للخطوط ١٫١';

  @override
  String get sourceHijri => 'التقويم الهجري';

  @override
  String get sourceHijriStatus =>
      'جدول أم القرى (حزمة hijri، رخصة BSD-2-Clause) · مؤقت';

  @override
  String get openLicences => 'تراخيص البرمجيات المفتوحة';

  @override
  String get rightsRecordedText => 'أدلة الحقوق مسجلة.';

  @override
  String surahMeta(String revelation, String ayahs) {
    return '$revelation · $ayahs';
  }

  @override
  String quranSourceLine(String version) {
    return 'نص القرآن: تنزيل، الرسم العثماني $version · tanzil.net';
  }

  @override
  String get reviewPending => 'بانتظار فحص المراجِع';

  @override
  String reviewDone(String name, String date) {
    return 'فحصه $name · $date';
  }

  @override
  String get sourceDialogTitle => 'عن نص القرآن هذا';

  @override
  String get sourceLabel => 'المصدر';

  @override
  String sourceValue(String name, String script, String version) {
    return '$name، الرسم $script، الإصدار $version';
  }

  @override
  String get linkLabel => 'الرابط';

  @override
  String get numberingLabel => 'الترقيم';

  @override
  String get numberingHafsBasmala =>
      'حفص (العدّ الكوفي)، كما في المصدر. البسملة هي الآية الأولى من الفاتحة.';

  @override
  String get checksLabel => 'الفحوص';

  @override
  String get checksText =>
      'تم التحقق من ملف المصدر كاملًا (٦٢٣٦ آية)؛ يُعاد التحقق من بصمة كل آية عند التحميل؛ تطابق حرفي مع مصدر مستقل.';

  @override
  String get reviewLabel => 'فحص المراجِع';

  @override
  String get licenceLabel => 'الترخيص (بنصه)';

  @override
  String get copyLink => 'نسخ الرابط';

  @override
  String get linkCopied => 'تم نسخ الرابط';

  @override
  String ayahReference(String surah, String surahNumber, String ayah) {
    return '$surah $surahNumber:$ayah';
  }

  @override
  String copiedAyah(String reference) {
    return 'تم نسخ $reference';
  }

  @override
  String quranAyahSemantics(String number) {
    return 'الآية $number';
  }

  @override
  String get unavailableRecitation => 'لا يوجد صوت تلاوة بعد.';

  @override
  String get unavailableTafsirText =>
      'لم يُزوَّد التفسير المكتوب لهذه الآية بعد.';

  @override
  String get unavailableTranslation => 'لا توجد ترجمة معتمدة بعد.';

  @override
  String get unavailableRecording => 'تسجيل الشيخ غير متاح على هذا الجهاز.';

  @override
  String get tafsirBadge => 'تفسير الشيخ · التسجيل الأصلي';

  @override
  String get notRecitation => 'شرح وتفسير، وليس تلاوة للقرآن';

  @override
  String get tafsirTitle => 'تفسير سورة الفاتحة';

  @override
  String get speakerName => 'Sheikh Calinuur';

  @override
  String get testingOnly => 'للاختبار فقط · غير مخصص للنشر';

  @override
  String get recordingNotInstalled =>
      'تسجيل تفسير الشيخ غير مثبت على هذا الجهاز.';

  @override
  String get recordingInstallHint => 'أعد تثبيت التطبيق لاستعادته.';

  @override
  String get recordingMismatch =>
      'هذا الملف ليس التسجيل الأصلي، لذا لن يُشغَّل.';

  @override
  String get playerPlay => 'تشغيل';

  @override
  String get playerPause => 'إيقاف مؤقت';

  @override
  String get playerReplay => 'إعادة التشغيل';

  @override
  String get playerBack10 => 'رجوع ١٠ ثوانٍ';

  @override
  String get playerForward10 => 'تقدّم ١٠ ثوانٍ';

  @override
  String get playerPosition => 'موضع التشغيل';

  @override
  String get playerError => 'تعذّر تشغيل التسجيل.';

  @override
  String get playerLoading => 'جارٍ التحميل…';

  @override
  String get syncPending => 'تمييز الآيات: بانتظار المراجعة';

  @override
  String syncFollowing(String ayahs, String kind) {
    return 'الآية $ayahs · $kind';
  }

  @override
  String get kindReading => 'تلاوة';

  @override
  String get kindExplanation => 'شرح';

  @override
  String get syncGap => 'لا يوجد مقطع مُراجَع في هذا الموضع';

  @override
  String get syncMismatch => 'الربط يخص تسجيلًا آخر';

  @override
  String get syncInvalid => 'الربط فيه أخطاء وتم إيقافه';

  @override
  String get sourceQuranTextFatiha =>
      'الفاتحة مثبتة · تنزيل، الرسم العثماني 1.1، بنصه · بانتظار فحص المراجِع';

  @override
  String noReviewedExplanation(String number) {
    return 'لا يوجد شرح مُراجَع للآية $number بعد.';
  }

  @override
  String syncFollowingRange(String ayahs, String kind, String range) {
    return 'الآية $ayahs · $kind · $range';
  }

  @override
  String syncSelectedNoExplanation(String number) {
    return 'الآية $number: لا يوجد شرح مُراجَع بعد';
  }

  @override
  String syncLoadingAyah(String number) {
    return 'الآية $number · بدء الشرح…';
  }

  @override
  String syncIntro(String range) {
    return 'مقدمة · $range';
  }

  @override
  String syncQa(String range) {
    return 'أسئلة وأجوبة · $range';
  }

  @override
  String get recordingPhoneOnly => 'تسجيل الشيخ يعمل في تطبيق أندرويد وiOS.';

  @override
  String syncCandidate(String ayahs, String range, String confidence) {
    return 'الآية $ayahs · $range · التوقيت لم يُراجَع بعد';
  }

  @override
  String syncSegmentFinished(String number) {
    return 'الآية $number: انتهى هذا المقطع · اضغط على الآية لسماعه مرة أخرى';
  }

  @override
  String get confidenceHigh => 'عالية';

  @override
  String get confidenceMedium => 'متوسطة';

  @override
  String get confidenceLow => 'منخفضة';

  @override
  String get autoScrollOn => 'التمرير التلقائي يعمل · اضغط على النص لإيقافه';

  @override
  String get autoScrollStop => 'إيقاف التمرير التلقائي';

  @override
  String get noTafsirForSurah =>
      'تسجيل تفسير الشيخ متاح لسورة الفاتحة فقط حتى الآن.';

  @override
  String get bookmarkAdded => 'أُضيفت العلامة';

  @override
  String get bookmarkRemoved => 'حُذفت العلامة';

  @override
  String get ayahRemoveBookmark => 'حذف العلامة';

  @override
  String get tabBookmarks => 'العلامات';

  @override
  String get bookmarksEmptyTitle => 'لا توجد علامات بعد';

  @override
  String get bookmarksEmptyBody =>
      'اضغط مطولًا على آية في القارئ واختر «علامة». تُحفظ العلامات على هذا الجهاز.';

  @override
  String bookmarkAyahLine(String reference) {
    return 'الآية $reference';
  }

  @override
  String get readingControls => 'إعدادات القراءة';

  @override
  String get readerDarkPage => 'صفحة قراءة داكنة';

  @override
  String textSizeValue(String size) {
    return 'حجم نص القرآن: $size';
  }

  @override
  String get quranTextSize => 'حجم نص القرآن';

  @override
  String get textSmaller => 'تصغير النص';

  @override
  String get textLarger => 'تكبير النص';

  @override
  String get textSizeReset => 'إعادة الضبط';

  @override
  String get previousSurah => 'السورة السابقة';

  @override
  String get nextSurah => 'السورة التالية';

  @override
  String get quranSearchTitle => 'البحث في القرآن';

  @override
  String get quranSearchHint => 'ابحث في النص العربي (التشكيل اختياري)';

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get quranSearchMinChars =>
      'اكتب حرفين عربيين على الأقل. يُتجاهل التشكيل والعلامات عند المطابقة، ويُعرض النص دائمًا كما هو في المصدر.';

  @override
  String quranSearchResults(String count) {
    return '$count آية';
  }

  @override
  String quranSearchManyResults(String count) {
    return 'أول $count آية · حدّد البحث لنتائج أقل';
  }

  @override
  String quranSearchSkipped(String count) {
    return '$count سورة لم تجتز التحقق ولم يُبحث فيها';
  }

  @override
  String aboutVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get aboutQuranBody =>
      'السور الـ ١١٤ كلها من نص تنزيل العثماني ١٫١، تُعرض كما هي حرفيًا. تُطابَق كل آية مع بصمتها المسجلة عند التحميل، وقد قورنت حرفًا حرفًا بمصدر ثانٍ. ما زالت مراجعة القارئ على الجهاز معلّقة.';

  @override
  String get aboutTafsirTitle => 'تفسير الشيخ علي نور';

  @override
  String get aboutTafsirBody =>
      'تفسير الشيخ المسجَّل لسورة الفاتحة، مضمَّن في التطبيق ويعمل دون اتصال. اضغط على آية لتسمع شرحه لها. توقيتات المقاطع ما زالت قيد المراجعة.';

  @override
  String get aboutPrivacyTitle => 'الخصوصية';

  @override
  String get aboutPrivacyBody =>
      'لا حساب ولا تتبّع. الإعدادات والعلامات وموضع قراءتك تبقى على هذا الجهاز.';

  @override
  String get openSourceLicences => 'تراخيص البرمجيات المفتوحة';

  @override
  String get sourceQuranTextStatus =>
      'السور الـ ١١٤ كلها · تنزيل العثماني ١٫١ حرفيًا · قورن بمصدر ثانٍ · مراجعة القارئ معلّقة';

  @override
  String get sourceQuranMetadataStatus =>
      'بيانات تنزيل ١٫٠ · ١١٤ سورة و٣٠ جزءًا و٦٠٤ صفحات لمصحف المدينة · قورنت بمصدر ثانٍ';

  @override
  String get logoSemantics => 'شعار الشيخ علي نور';

  @override
  String pageLabel(String page) {
    return 'صفحة $page';
  }

  @override
  String get nextPage => 'الصفحة التالية';

  @override
  String get previousPage => 'الصفحة السابقة';

  @override
  String get goToPageTitle => 'الانتقال إلى صفحة';

  @override
  String goToPageHint(String first, String last) {
    return 'رقم الصفحة، $first–$last';
  }

  @override
  String goToPageInvalid(String first, String last) {
    return 'أدخل رقم صفحة من $first إلى $last.';
  }

  @override
  String get goToPageAction => 'انتقال';

  @override
  String get readingLayout => 'طريقة العرض';

  @override
  String get layoutPages => 'صفحات';

  @override
  String get layoutSurah => 'السورة كاملة';

  @override
  String get layoutPagesNote =>
      'حدود صفحات مصحف المدينة (٦٠٤ صفحات). الأسطر من ترتيب التطبيق، وليست كما في المصحف المطبوع.';

  @override
  String get pagesLabel => 'الصفحات';

  @override
  String get pagesSourceValue =>
      'حدود صفحات مصحف المدينة، ٦٠٤ صفحات، من بيانات تنزيل. قورنت صفحة كل آية بمصدر Quran Foundation. ترتيب الأسطر من التطبيق وليس كالمصحف المطبوع.';

  @override
  String get pageTextUnverified =>
      'تعذّر التحقق من نص هذه الصفحة، لذلك لا يُعرض.';

  @override
  String get recordingPreparing => 'جارٍ تجهيز تسجيل الشيخ…';

  @override
  String get recordingUnpackFailed =>
      'تعذّر تجهيز تسجيل الشيخ على هذا الجهاز. وفّر بعض المساحة ثم أعد فتح التطبيق.';

  @override
  String get recordingNotInThisBuild =>
      'بُنيت هذه النسخة من التطبيق دون تسجيل الشيخ.';

  @override
  String syncReadingThenExplanation(String number, String range) {
    return 'يقرأ الشيخ الآية $number ثم يشرحها · $range';
  }
}
