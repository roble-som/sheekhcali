import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/localized_digits.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../application/tafsir_player.dart';
import '../data/recording_repository.dart';
import '../domain/alignment.dart';
import '../domain/recording.dart';
import '../domain/span_index.dart';

/// "m:ss" or "h:mm:ss" with Western digits, always LTR (spec §6.6).
String formatPlaybackTime(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

/// The Sheikh's Tafsir player docked under the Quran text (concept 11/12).
/// Hidden entirely when the recording's rights don't allow this build (C-26).
class TafsirPlayerBar extends ConsumerWidget {
  const TafsirPlayerBar({super.key, required this.index, this.selectedAyah});

  final SpanIndex? index;

  /// The ayah the user last tapped, if any.
  final int? selectedAyah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(fatihaRecordingProvider);
    return status.when(
      loading: () => const _Shell(child: LinearProgressIndicator(minHeight: 2)),
      error: (e, s) => _Shell(
        child: _Notice(
          icon: Icons.error_outline,
          text: AppLocalizations.of(context).unavailableRecording,
        ),
      ),
      data: (s) => switch (s) {
        RecordingNotPermitted() => const SizedBox.shrink(),
        RecordingPlatformUnsupported() => _Shell(
          child: _Notice(
            icon: Icons.phone_android,
            text: AppLocalizations.of(context).recordingPhoneOnly,
          ),
        ),
        RecordingNotInstalled() => _Shell(
          child: _Notice(
            icon: Icons.headphones,
            text: AppLocalizations.of(context).recordingNotInstalled,
            hint: AppLocalizations.of(context).recordingInstallHint,
          ),
        ),
        RecordingChecksumMismatch() => _Shell(
          child: _Notice(
            icon: Icons.gpp_bad_outlined,
            text: AppLocalizations.of(context).recordingMismatch,
          ),
        ),
        RecordingReady(:final path, :final info) => _Shell(
          child: _Player(
            path: path,
            info: info,
            index: index,
            selectedAyah: selectedAyah,
          ),
        ),
      },
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ReaderColors.bar,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: child,
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.hint});

  final IconData icon;
  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final styles = context.text;
    return Row(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, style: styles.noticeTitle),
              if (hint != null) ...[
                const SizedBox(height: 2),
                Text(hint!, style: styles.noticeBody),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Player extends ConsumerStatefulWidget {
  const _Player({
    required this.path,
    required this.info,
    required this.index,
    this.selectedAyah,
  });

  final String path;
  final RecordingInfo info;
  final SpanIndex? index;
  final int? selectedAyah;

  @override
  ConsumerState<_Player> createState() => _PlayerState();
}

class _PlayerState extends ConsumerState<_Player> {
  double? _dragMs;

  Future<void> _togglePlay(TafsirPlayer player, TafsirPlaybackState s) async {
    final l10n = AppLocalizations.of(context);
    if (s.phase == TafsirPhase.idle || s.phase == TafsirPhase.error) {
      await player.load(
        path: widget.path,
        title: l10n.tafsirTitle,
        artist: l10n.speakerName,
      );
      if (player.current.phase == TafsirPhase.error) return;
    }
    if (player.current.isPlaying) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> _skip(
    TafsirPlayer player,
    TafsirPlaybackState s,
    int seconds,
  ) async {
    if (s.phase == TafsirPhase.idle) return;
    final max = (s.duration ?? Duration(milliseconds: widget.info.durationMs))
        .inMilliseconds;
    final target = (s.position.inMilliseconds + seconds * 1000).clamp(0, max);
    await player.seek(Duration(milliseconds: target));
  }

  String _syncLine(AppLocalizations l10n, TafsirPlaybackState s) {
    final locale = Localizations.localeOf(context);
    String d(int n) => localizeDigits('$n', locale);
    final index = widget.index;
    final selected = widget.selectedAyah;
    if (index == null || !index.isUsable) {
      if (selected != null &&
          index?.unavailableReason != SyncUnavailableReason.recordingMismatch) {
        return l10n.syncSelectedNoExplanation(d(selected));
      }
      return switch (index?.unavailableReason) {
        SyncUnavailableReason.recordingMismatch => l10n.syncMismatch,
        SyncUnavailableReason.invalid => l10n.syncInvalid,
        _ => l10n.syncPending,
      };
    }
    // The last tapped ayah has no explanation: say so until the next tap.
    if (selected != null && index.explanationForAyah(selected) == null) {
      return l10n.syncSelectedNoExplanation(d(selected));
    }
    final span = index.activeAt(s.position.inMilliseconds);
    if (span == null) {
      if (selected != null &&
          (s.phase == TafsirPhase.loading ||
              s.phase == TafsirPhase.buffering)) {
        return l10n.syncLoadingAyah(d(selected));
      }
      return l10n.syncGap;
    }
    final range =
        '${formatPlaybackTime(Duration(milliseconds: span.startMs))}–'
        '${formatPlaybackTime(Duration(milliseconds: span.endMs))}';
    if (span.kind == SpanKind.intro) return l10n.syncIntro(range);
    if (span.kind == SpanKind.qa) return l10n.syncQa(range);
    final ayahs = span.ayahs.map(d).join('–');
    return l10n.syncFollowingRange(
      ayahs,
      span.kind == SpanKind.reading ? l10n.kindReading : l10n.kindExplanation,
      range,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.text;
    final player = ref.watch(tafsirPlayerProvider);
    final s = ref.watch(tafsirPlaybackProvider).value ?? player.current;
    final durationMs =
        (s.duration ?? Duration(milliseconds: widget.info.durationMs))
            .inMilliseconds;
    final positionMs = (_dragMs ?? s.position.inMilliseconds.toDouble())
        .clamp(0, durationMs.toDouble())
        .toDouble();
    final busy =
        s.phase == TafsirPhase.loading || s.phase == TafsirPhase.buffering;
    final completed = s.phase == TafsirPhase.completed;
    final white70 = Colors.white.withValues(alpha: 0.75);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Badge and "testing only" wrap rather than truncate.
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.record_voice_over,
                  size: 18,
                  color: HomeColors.goldLabel,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.tafsirBadge,
                    style: styles.noticeTitle.copyWith(
                      color: HomeColors.goldLabel,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white38),
              ),
              child: Text(
                l10n.testingOnly,
                style: styles.placeholderLabel.copyWith(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${l10n.tafsirTitle} · ${l10n.speakerName}',
          style: styles.noticeTitle.copyWith(fontSize: 14),
        ),
        Text(
          l10n.notRecitation,
          style: styles.noticeBody.copyWith(color: white70),
        ),
        if (s.phase == TafsirPhase.error)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.playerError,
              style: styles.noticeBody.copyWith(color: const Color(0xFFFFB4AB)),
            ),
          ),
        Semantics(
          label: l10n.playerPosition,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: HomeColors.gold,
              inactiveTrackColor: Colors.white24,
              thumbColor: HomeColors.gold,
            ),
            child: Directionality(
              // Media timelines run left to right in both languages.
              textDirection: TextDirection.ltr,
              child: Slider(
                min: 0,
                max: durationMs.toDouble(),
                value: positionMs,
                onChanged: s.phase == TafsirPhase.idle
                    ? null
                    : (v) => setState(() => _dragMs = v),
                onChangeEnd: (v) async {
                  setState(() => _dragMs = null);
                  await player.seek(Duration(milliseconds: v.round()));
                },
              ),
            ),
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Text(
                formatPlaybackTime(Duration(milliseconds: positionMs.round())),
                key: const ValueKey('tafsir-position'),
                style: styles.noticeBody.copyWith(color: white70),
              ),
              const Spacer(),
              IconButton(
                tooltip: l10n.playerBack10,
                onPressed: () => _skip(player, s, -10),
                icon: const Icon(Icons.replay_10, color: Colors.white),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 56,
                height: 56,
                child: busy
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: HomeColors.gold,
                        ),
                      )
                    : IconButton(
                        key: const ValueKey('tafsir-play'),
                        tooltip: s.isPlaying
                            ? l10n.playerPause
                            : (completed ? l10n.playerReplay : l10n.playerPlay),
                        onPressed: () => _togglePlay(player, s),
                        icon: Icon(
                          s.isPlaying
                              ? Icons.pause_circle_filled
                              : (completed
                                    ? Icons.replay_circle_filled
                                    : Icons.play_circle_filled),
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: l10n.playerForward10,
                onPressed: () => _skip(player, s, 10),
                icon: const Icon(Icons.forward_10, color: Colors.white),
              ),
              const Spacer(),
              Text(
                formatPlaybackTime(Duration(milliseconds: durationMs)),
                key: const ValueKey('tafsir-duration'),
                style: styles.noticeBody.copyWith(color: white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(
              widget.index?.isUsable == true
                  ? Icons.sync
                  : Icons.pending_outlined,
              size: 15,
              color: white70,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _syncLine(l10n, s),
                key: const ValueKey('tafsir-sync'),
                style: styles.noticeBody.copyWith(color: white70),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
