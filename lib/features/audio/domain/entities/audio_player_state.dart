import 'package:fihirana/features/hymn/domain/entities/hymn.dart';

class AudioPlayerState {
  final Hymn? currentHymn;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final String? error;
  final List<Hymn> playlist;
  final int currentPlaylistIndex;
  final bool isShuffled;
  final bool isRepeating;

  const AudioPlayerState({
    this.currentHymn,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
    this.playlist = const [],
    this.currentPlaylistIndex = -1,
    this.isShuffled = false,
    this.isRepeating = false,
  });

  AudioPlayerState copyWith({
    Hymn? currentHymn,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    String? error,
    List<Hymn>? playlist,
    int? currentPlaylistIndex,
    bool? isShuffled,
    bool? isRepeating,
  }) {
    return AudioPlayerState(
      currentHymn: currentHymn ?? this.currentHymn,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error ?? this.error,
      playlist: playlist ?? this.playlist,
      currentPlaylistIndex: currentPlaylistIndex ?? this.currentPlaylistIndex,
      isShuffled: isShuffled ?? this.isShuffled,
      isRepeating: isRepeating ?? this.isRepeating,
    );
  }

  bool get hasError => error != null;
  bool get canPlayNext =>
      playlist.isNotEmpty && currentPlaylistIndex < playlist.length - 1;
  bool get canPlayPrevious => playlist.isNotEmpty && currentPlaylistIndex > 0;
  bool get hasNext => canPlayNext || isRepeating;
  bool get hasPrevious => canPlayPrevious || isRepeating;
}
