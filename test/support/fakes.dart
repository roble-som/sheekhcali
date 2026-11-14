import 'dart:async';

import 'package:sheekhcali/features/tafsir_audio/application/tafsir_player.dart';
import 'package:sheekhcali/features/tafsir_audio/data/recording_repository.dart';
import 'package:sheekhcali/features/tafsir_audio/domain/recording.dart';

/// Returns a fixed status (no file system, no hashing).
class FakeRecordingRepository implements RecordingRepository {
  FakeRecordingRepository(this.status);

  final RecordingStatus status;

  @override
  Future<RecordingStatus> locate(RecordingInfo info) async => status;
}

/// A scriptable player: records commands, and lets tests move the position.
class FakeTafsirPlayer implements TafsirPlayer {
  final _states = StreamController<TafsirPlaybackState>.broadcast();
  TafsirPlaybackState _current = const TafsirPlaybackState();
  final commands = <String>[];

  /// Simulates a load failure on the next [load].
  bool failNextLoad = false;

  @override
  Stream<TafsirPlaybackState> get states => _states.stream;

  @override
  TafsirPlaybackState get current => _current;

  void emit(TafsirPlaybackState s) {
    _current = s;
    _states.add(s);
  }

  /// Moves the playhead as if audio were playing.
  void setPosition(Duration p) => emit(_current.copyWith(position: p));

  @override
  Future<void> load({
    required String path,
    required String title,
    required String artist,
  }) async {
    commands.add('load:$path');
    if (failNextLoad) {
      failNextLoad = false;
      emit(_current.copyWith(phase: TafsirPhase.error, error: 'fake failure'));
      return;
    }
    emit(
      _current.copyWith(
        phase: TafsirPhase.ready,
        duration: Duration(milliseconds: fatihaTafsirR3.durationMs),
      ),
    );
  }

  /// Paths passed to [preload] (kept apart from [commands]).
  final preloads = <String>[];

  @override
  Future<void> preload({
    required String path,
    required String title,
    required String artist,
  }) async {
    preloads.add(path);
  }

  @override
  Future<void> play() async {
    commands.add('play');
    emit(_current.copyWith(phase: TafsirPhase.playing));
  }

  @override
  Future<void> pause() async {
    commands.add('pause');
    emit(_current.copyWith(phase: TafsirPhase.paused));
  }

  @override
  Future<void> seek(Duration position) async {
    commands.add('seek:${position.inMilliseconds}');
    emit(_current.copyWith(position: position));
  }

  @override
  Future<void> dispose() async => _states.close();
}
