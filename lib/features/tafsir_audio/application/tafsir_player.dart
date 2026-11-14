import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

enum TafsirPhase {
  idle,
  loading,
  ready,
  playing,
  paused,
  buffering,
  completed,
  error,
}

@immutable
class TafsirPlaybackState {
  const TafsirPlaybackState({
    this.phase = TafsirPhase.idle,
    this.position = Duration.zero,
    this.duration,
    this.error,
  });

  final TafsirPhase phase;
  final Duration position;
  final Duration? duration;
  final String? error;

  bool get isPlaying =>
      phase == TafsirPhase.playing || phase == TafsirPhase.buffering;

  TafsirPlaybackState copyWith({
    TafsirPhase? phase,
    Duration? position,
    Duration? duration,
    String? error,
  }) => TafsirPlaybackState(
    phase: phase ?? this.phase,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    error: error,
  );
}

/// Everything the UI needs from an audio player. Tests use a fake.
abstract interface class TafsirPlayer {
  Stream<TafsirPlaybackState> get states;
  TafsirPlaybackState get current;
  Future<void> load({
    required String path,
    required String title,
    required String artist,
  });

  /// Loads the recording and prepares it so that the first seek is instant,
  /// without playing anything. Does nothing if something is already loaded.
  Future<void> preload({
    required String path,
    required String title,
    required String artist,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> dispose();
}

/// just_audio behind an audio_service handler: background playback plus
/// lock-screen and notification controls (DESIGN_SYSTEM_SPECIFICATION §8.11).
///
/// Seeking: the recording is a VBR MP3 (R3: 32–40 kbps), where ExoPlayer's
/// default Xing-table seeking is approximate. Index seeking makes seeks exact
/// on the original's timeline, which the alignment timestamps rely on (T-15).
class ServiceTafsirPlayer implements TafsirPlayer {
  ServiceTafsirPlayer();

  static Future<_TafsirAudioHandler>? _handlerFuture;

  final _states = StreamController<TafsirPlaybackState>.broadcast();
  TafsirPlaybackState _current = const TafsirPlaybackState();
  final _subs = <StreamSubscription<Object?>>[];
  _TafsirAudioHandler? _handler;

  @override
  Stream<TafsirPlaybackState> get states => _states.stream;

  @override
  TafsirPlaybackState get current => _current;

  void _emit(TafsirPlaybackState s) {
    _current = s;
    if (!_states.isClosed) _states.add(s);
  }

  /// Player updates while [preload] warms up are not shown (the playhead
  /// jumps to the end and back); a user action ends the warm-up at once.
  bool _warming = false;

  /// Counts user seeks and plays, so a warm-up never undoes one.
  int _userActions = 0;

  /// The load in progress, if any: play and seek wait for it.
  Future<void>? _loading;

  void _emitFromPlayer(TafsirPlaybackState s) {
    if (_warming) {
      _current = s;
      return;
    }
    _emit(s);
  }

  static const _permissions = MethodChannel('sheekhcalinuur/permissions');
  static bool _askedForNotifications = false;

  /// Android 13+: ask once for the notification permission that shows the
  /// playback controls. Playback works whatever the answer.
  static Future<void> _askForNotificationsOnce() async {
    if (_askedForNotifications ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _askedForNotifications = true;
    try {
      await _permissions.invokeMethod<void>('requestNotifications');
    } on Object {
      // Not available (tests, other platforms): ignore.
    }
  }

  Future<_TafsirAudioHandler> _ensureHandler() {
    return _handlerFuture ??= AudioService.init(
      builder: _TafsirAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'sheekhcalinuur.lessons.playback',
        androidNotificationChannelName: 'Lesson playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  }

  @override
  Future<void> load({
    required String path,
    required String title,
    required String artist,
  }) {
    final loading = _load(path: path, title: title, artist: artist);
    _loading = loading;
    return loading.whenComplete(() {
      if (identical(_loading, loading)) _loading = null;
    });
  }

  /// The MP3 is variable-bitrate and played with exact (index) seeking, so
  /// ExoPlayer builds its seek index by reading the file up to the first
  /// seek target. On a phone that took 7–10 s for a tap late in the lesson.
  /// Seeking to the end once, silently, builds the whole index while the
  /// page is open; every later seek is then immediate.
  @override
  Future<void> preload({
    required String path,
    required String title,
    required String artist,
  }) async {
    if (_current.phase != TafsirPhase.idle) return;
    final before = _userActions;
    _warming = true;
    try {
      await load(path: path, title: title, artist: artist);
      final h = _handler;
      final d = h?.player.duration;
      if (h == null || d == null || before != _userActions) return;
      final target = d - const Duration(seconds: 2);
      await h.player.seek(target);
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (before == _userActions && DateTime.now().isBefore(deadline)) {
        final p = h.player;
        if (p.processingState == ProcessingState.ready &&
            p.bufferedPosition >= target) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (before == _userActions) await h.player.seek(Duration.zero);
    } on Object {
      // A failed warm-up only means the first seek is slower.
    } finally {
      if (before == _userActions && _warming) {
        _warming = false;
        if (_current.phase != TafsirPhase.error) {
          _emit(
            _current.copyWith(
              phase: TafsirPhase.ready,
              position: Duration.zero,
            ),
          );
        }
      }
    }
  }

  /// A user seek or play: ends any warm-up and waits for a load in progress.
  Future<_TafsirAudioHandler?> _userAction() async {
    _userActions++;
    _warming = false;
    final loading = _loading;
    if (loading != null) await loading;
    return _handler;
  }

  Future<void> _load({
    required String path,
    required String title,
    required String artist,
  }) async {
    _emitFromPlayer(_current.copyWith(phase: TafsirPhase.loading));
    try {
      final handler = _handler = await _ensureHandler();
      final player = handler.player;
      for (final s in _subs) {
        await s.cancel();
      }
      _subs
        ..clear()
        ..add(
          player.playerStateStream.listen(
            (ps) => _emitFromPlayer(_map(ps, player)),
          ),
        )
        ..add(
          player.positionStream.listen(
            (p) => _emitFromPlayer(
              _current.copyWith(position: p, phase: _current.phase),
            ),
          ),
        )
        ..add(
          player.durationStream.listen(
            (d) => _emitFromPlayer(
              _current.copyWith(duration: d, phase: _current.phase),
            ),
          ),
        );
      final duration = await handler.open(
        path: path,
        title: title,
        artist: artist,
      );
      _emitFromPlayer(
        _current.copyWith(duration: duration, phase: TafsirPhase.ready),
      );
    } on Object catch (e) {
      _warming = false;
      _emit(_current.copyWith(phase: TafsirPhase.error, error: '$e'));
    }
  }

  TafsirPlaybackState _map(PlayerState ps, AudioPlayer player) {
    final phase = switch (ps.processingState) {
      ProcessingState.idle => TafsirPhase.idle,
      ProcessingState.loading => TafsirPhase.loading,
      ProcessingState.buffering => TafsirPhase.buffering,
      ProcessingState.completed => TafsirPhase.completed,
      ProcessingState.ready =>
        ps.playing ? TafsirPhase.playing : TafsirPhase.paused,
    };
    return _current.copyWith(phase: phase, position: player.position);
  }

  @override
  Future<void> play() async {
    final h = await _userAction();
    if (h == null) return;
    // Android 13+: asked once, at the first real playback (not on preload).
    await _askForNotificationsOnce();
    if (_current.phase == TafsirPhase.completed) await h.seek(Duration.zero);
    await h.play();
  }

  @override
  Future<void> pause() async => _handler?.pause();

  @override
  Future<void> seek(Duration position) async {
    final h = await _userAction();
    if (h == null) return;
    // Emit at once so the highlight follows the seek without waiting for the
    // next position tick.
    _emit(_current.copyWith(position: position, phase: _current.phase));
    await h.seek(position);
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _handler?.stop();
    await _states.close();
  }
}

class _TafsirAudioHandler extends BaseAudioHandler with SeekHandler {
  _TafsirAudioHandler() {
    player.playbackEventStream.listen((_) => _broadcast());
    player.playerStateStream.listen((_) => _broadcast());
  }

  final player = AudioPlayer();

  Future<Duration?> open({
    required String path,
    required String title,
    required String artist,
  }) async {
    final duration = await player.setAudioSource(
      ProgressiveAudioSource(
        Uri.file(path),
        options: const ProgressiveAudioSourceOptions(
          androidExtractorOptions: AndroidExtractorOptions(
            constantBitrateSeekingEnabled: false,
            mp3Flags: AndroidExtractorOptions.flagMp3EnableIndexSeeking,
          ),
        ),
      ),
    );
    mediaItem.add(
      MediaItem(id: path, title: title, artist: artist, duration: duration),
    );
    return duration;
  }

  void _broadcast() {
    final playing = player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.fastForward,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: switch (player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
      ),
    );
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }
}

/// One player for the app. Tests override it with a fake.
final tafsirPlayerProvider = Provider<TafsirPlayer>((ref) {
  final player = ServiceTafsirPlayer();
  ref.onDispose(player.dispose);
  return player;
});

final tafsirPlaybackProvider = StreamProvider<TafsirPlaybackState>((ref) {
  final player = ref.watch(tafsirPlayerProvider);
  return player.states;
});
