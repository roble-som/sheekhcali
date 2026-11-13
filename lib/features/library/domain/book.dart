import 'package:flutter/foundation.dart';

/// Book categories from master prompt §6.2. Administrators can add more later
/// (they come from the CMS in Phase 2).
enum BookCategory {
  tafsir,
  hadith,
  fiqh,
  aqeedah,
  seerah,
  history,
  arabicLanguage,
  quranSciences,
  education,
  other,
}

/// Collection types from the Phase 0 spec §9.
enum CollectionType {
  sheikhOfficial,
  islamicOther,
  quranRelated,
  tafsir,
  lessonDocument,
}

/// Content status vocabulary (C-11).
enum ContentStatus {
  missing,
  imported,
  processing,
  needsVerification,
  verified,
  approvedForPublication,
  published,
  rejected,
}

@immutable
class BookChapter {
  const BookChapter({required this.number, this.title, this.lessonCount = 0});

  final int number;

  /// Null when not recorded; the UI then shows only the number.
  final String? title;
  final int lessonCount;
}

@immutable
class BookVolume {
  const BookVolume({
    required this.number,
    this.title,
    this.chapters = const [],
  });

  final int number;
  final String? title;
  final List<BookChapter> chapters;
}

/// A book in the library. Optional fields are **null when not recorded**;
/// nothing is guessed (master prompt §6.1).
@immutable
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.category,
    required this.collection,
    required this.languageCode,
    required this.status,
    this.titleEnglish,
    this.author,
    this.edition,
    this.publisher,
    this.pageCount,
    this.volumes = const [],
    this.hasAudio = false,
    this.hasTranscript = false,
    this.isSynced = false,
    this.isDownloaded = false,
    this.rightsRecorded = false,
    this.isPreview = false,
  });

  final String id;

  /// Original title, in the book's own script.
  final String title;
  final String? titleEnglish;
  final String? author;
  final String? edition;
  final String? publisher;
  final int? pageCount;
  final BookCategory category;
  final CollectionType collection;

  /// ISO 639-1 code of the book's language (ar, so, en).
  final String languageCode;
  final ContentStatus status;
  final List<BookVolume> volumes;
  final bool hasAudio;
  final bool hasTranscript;
  final bool isSynced;
  final bool isDownloaded;
  final bool rightsRecorded;

  /// Design preview data (debug builds only). It is never real content.
  final bool isPreview;

  int get lessonCount => volumes.fold(
    0,
    (sum, v) => sum + v.chapters.fold(0, (s, c) => s + c.lessonCount),
  );
}
