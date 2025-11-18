import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/hymn.dart';
import '../services/audio_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  final Hymn hymn;

  const AudioPlayerWidget({
    Key? key,
    required this.hymn,
  }) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioService _audioService = AudioService();
  bool _isLoading = false;
  Duration? _duration;
  Duration? _position;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _audioService.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
        _isLoading = state.processingState == ProcessingState.loading ||
                    state.processingState == ProcessingState.buffering;
      });
    });

    _audioService.positionStream.listen((position) {
      setState(() {
        _position = position;
      });
    });

    _audioService.durationStream.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    if (_audioService.currentHymn?.id == widget.hymn.id) {
      setState(() {
        _isPlaying = _audioService.isPlaying;
        _position = _audioService.currentPosition;
        _duration = _audioService.duration;
      });
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_audioService.currentHymn?.id != widget.hymn.id) {
        setState(() => _isLoading = true);
        await _audioService.playHymn(widget.hymn);
      } else if (_isPlaying) {
        await _audioService.pause();
      } else {
        await _audioService.resume();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to play audio: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _stop() async {
    try {
      await _audioService.stop();
    } catch (e) {
      _showErrorSnackBar('Failed to stop audio: $e');
    }
  }

  void _seekTo(double value) {
    final position = Duration(milliseconds: (value * (_duration?.inMilliseconds ?? 0)).round());
    _audioService.seekTo(position);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.hymn.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Hymn ${widget.hymn.hymnNumber}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(_formatDuration(_position)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _duration != null && _position != null
                        ? (_position!.inMilliseconds / _duration!.inMilliseconds).clamp(0.0, 1.0)
                        : 0.0,
                    onChanged: _duration != null ? _seekTo : null,
                    min: 0.0,
                    max: 1.0,
                  ),
                ),
              ),
              Text(_formatDuration(_duration)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _isLoading ? null : _togglePlayPause,
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
              ),
              IconButton(
                onPressed: _isLoading ? null : _stop,
                icon: const Icon(
                  Icons.stop_circle,
                  size: 36,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}