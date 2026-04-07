import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

enum AudioPlayerStatus { initial, loading, ready, playing, paused, completed, error }

class AudioPlayerState extends Equatable {
  const AudioPlayerState({
    this.status = AudioPlayerStatus.initial,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
  });

  final AudioPlayerStatus status;
  final Duration position;
  final Duration duration;
  final String? errorMessage;

  bool get isPlaying => status == AudioPlayerStatus.playing;

  AudioPlayerState copyWith({
    AudioPlayerStatus? status,
    Duration? position,
    Duration? duration,
    String? errorMessage,
  }) {
    return AudioPlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, position, duration, errorMessage];
}

class AudioPlayerCubit extends Cubit<AudioPlayerState> {
  AudioPlayerCubit() : super(const AudioPlayerState()) {
    _player = AudioPlayer();
    _subscribeToStreams();
  }

  late final AudioPlayer _player;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  void _subscribeToStreams() {
    _positionSub = _player.positionStream.listen((pos) {
      if (!isClosed) {
        emit(state.copyWith(position: pos));
      }
    });

    _playerStateSub = _player.playerStateStream.listen((ps) {
      if (isClosed) return;
      if (ps.processingState == ProcessingState.completed) {
        emit(state.copyWith(
          status: AudioPlayerStatus.completed,
          position: state.duration,
        ));
      } else if (ps.playing) {
        emit(state.copyWith(status: AudioPlayerStatus.playing));
      } else if (state.status == AudioPlayerStatus.playing) {
        emit(state.copyWith(status: AudioPlayerStatus.paused));
      }
    });
  }

  Future<void> loadAudio(String audioPath) async {
    final localPath = _resolveLocalPath(audioPath);
    if (localPath == null) {
      emit(state.copyWith(
        status: AudioPlayerStatus.error,
        errorMessage: 'Invalid audio file path',
      ));
      return;
    }

    final file = File(localPath);
    if (!await file.exists()) {
      emit(state.copyWith(
        status: AudioPlayerStatus.error,
        errorMessage: 'Audio file not found on device',
      ));
      return;
    }

    try {
      emit(state.copyWith(status: AudioPlayerStatus.loading));
      final dur = await _player.setFilePath(localPath);
      emit(state.copyWith(
        status: AudioPlayerStatus.ready,
        duration: dur ?? Duration.zero,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: AudioPlayerStatus.error,
        errorMessage: 'Could not load audio file',
      ));
    }
  }

  Future<void> togglePlayPause() async {
    switch (state.status) {
      case AudioPlayerStatus.playing:
        await _player.pause();
      case AudioPlayerStatus.completed:
        await _player.seek(Duration.zero);
        await _player.play();
      case AudioPlayerStatus.ready:
      case AudioPlayerStatus.paused:
        await _player.play();
      default:
        break;
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  String? _resolveLocalPath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('file://')) {
      return Uri.tryParse(trimmed)?.toFilePath();
    }
    if (trimmed.startsWith('/') || trimmed.contains(':\\')) {
      return trimmed;
    }
    return null;
  }

  @override
  Future<void> close() async {
    await _positionSub?.cancel();
    await _playerStateSub?.cancel();
    await _player.dispose();
    return super.close();
  }
}
