import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Bidi;

import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/book.dart';

/// The book's cover. No cover images exist yet, so this is the typographic
/// fallback from the design spec: a toned card with the book's own title.
/// **No picture is ever invented.**
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.book,
    this.width = 84,
    this.height = 118,
    this.showTitle = true,
  });

  final Book book;
  final double width;
  final double height;
  final bool showTitle;

  static const _tones = <List<Color>>[
    [Color(0xFF2C5A3C), Color(0xFF173D24)], // green
    [Color(0xFFB99645), Color(0xFF8A6A1F)], // gold
    [Color(0xFF2E5E63), Color(0xFF19494D)], // teal
  ];

  @override
  Widget build(BuildContext context) {
    final tone = _tones[book.category.index % _tones.length];
    final rtlTitle = Bidi.detectRtlDirectionality(book.title);
    return Semantics(
      image: true,
      label: AppLocalizations.of(context).coverSemantics(book.title),
      excludeSemantics: true,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: tone,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: AlignmentDirectional.bottomStart,
        child: showTitle
            ? Text(
                book.title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textDirection: rtlTitle ? TextDirection.rtl : TextDirection.ltr,
                style: TextStyle(
                  fontFamily: rtlTitle ? AppFonts.arabicUi : AppFonts.latin,
                  fontFamilyFallback: const [AppFonts.arabicUi, AppFonts.latin],
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: width >= 90 ? 13 : 11.5,
                  height: 1.3,
                ),
              )
            : null,
      ),
    );
  }
}
