class AudioTrack {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final Duration duration;
  final String? audioUrl;
  final String? localPath;
  final bool isLocal;
  final DateTime createdAt;

  const AudioTrack({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    required this.duration,
    this.audioUrl,
    this.localPath,
    this.isLocal = false,
    required this.createdAt,
  });

  AudioTrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? audioUrl,
    String? localPath,
    bool? isLocal,
    DateTime? createdAt,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      localPath: localPath ?? this.localPath,
      isLocal: isLocal ?? this.isLocal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayTitle => title;
  String get displaySubtitle => artist ?? album ?? '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration.inMilliseconds,
      'audioUrl': audioUrl,
      'localPath': localPath,
      'isLocal': isLocal,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      duration: Duration(milliseconds: json['duration']),
      audioUrl: json['audioUrl'],
      localPath: json['localPath'],
      isLocal: json['isLocal'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
