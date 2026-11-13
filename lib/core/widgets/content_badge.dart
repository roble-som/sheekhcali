import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum BadgeTone { neutral, positive, pending, preview }

/// Quiet status chip: an icon plus a text label, so colour is never the only
/// signal (DESIGN_SYSTEM_SPECIFICATION §5, §10).
class ContentBadge extends StatelessWidget {
  const ContentBadge({
    super.key,
    required this.label,
    required this.icon,
    this.tone = BadgeTone.neutral,
  });

  final String label;
  final IconData icon;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      BadgeTone.neutral => ReaderColors.icon,
      BadgeTone.positive => SemanticColors.verified,
      BadgeTone.pending => SemanticColors.draft,
      BadgeTone.preview => const Color(0xFF6A4E12),
    };
    final fill = tone == BadgeTone.preview ? const Color(0xFFF2E3C2) : null;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 2, 8, 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.placeholderLabel.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
