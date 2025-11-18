import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/hymn.dart';
import '../services/audio_service.dart';
import '../controller/color_controller.dart';
import 'package:get/get.dart';

class CompactAudioPlayerWidget extends StatefulWidget {
  final Hymn hymn;

  const CompactAudioPlayerWidget({
    Key? key,
    required this.hymn,
  }) : super(key: key);

  @override
  State<CompactAudioPlayerWidget> createState() => _CompactAudioPlayerWidgetState();
}

class _CompactAudioPlayerWidgetState extends State<CompactAudioPlayerWidget> {
  final AudioService _audioService = AudioService.instance;
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
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading = state.processingState == ProcessingState.loading ||
                      state.processingState == ProcessingState.buffering;
        });
      }
    });

    _audioService.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _audioService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    final ColorController colorController = Get.find<ColorController>();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorController.backgroundColor.value,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorController.primaryColor.value.withOpacity(0.3),
          width: 1,
        ),
      ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.hymn.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorController.textColor.value,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Hymn ${widget.hymn.hymnNumber}',
              style: TextStyle(
                fontSize: 12,
                color: colorController.textColor.value.withOpacity(0.7),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatDuration(_position),
                style: TextStyle(
                  fontSize: 10,
                  color: colorController.textColor.value.withOpacity(0.7),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                    trackHeight: 2,
                    activeTrackColor: colorController.primaryColor.value,
                    inactiveTrackColor: colorController.primaryColor.value.withOpacity(0.3),
                    thumbColor: colorController.primaryColor.value,
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
              Text(
                _formatDuration(_duration),
                style: TextStyle(
                  fontSize: 10,
                  color: colorController.textColor.value.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _isLoading ? null : _togglePlayPause,
                icon: _isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorController.primaryColor.value,
                        ),
                      )
                    : Icon(
                        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        size: 32,
                        color: colorController.primaryColor.value,
                      ),
              ),
              IconButton(
                onPressed: _isLoading ? null : _stop,
                icon: Icon(
                  Icons.stop_circle,
                  size: 24,
                  color: colorController.textColor.value.withOpacity(0.6),
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