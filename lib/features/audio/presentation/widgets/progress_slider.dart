import 'package:flutter/material.dart';

class ProgressSlider extends StatefulWidget {
  final Duration? duration;
  final Duration? position;
  final bool isDragging;
  final double dragValue;
  final Function(double) onChanged;
  final Function(double) onChangeEnd;

  const ProgressSlider({
    super.key,
    required this.duration,
    required this.position,
    required this.isDragging,
    required this.dragValue,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  State<ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<ProgressSlider> {
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    const secondaryTextColor = Colors.white70;

    return Column(
      children: [
        // Progress Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: widget.isDragging
                ? widget.dragValue
                : (widget.duration != null &&
                        widget.position != null &&
                        widget.duration!.inMilliseconds > 0)
                    ? (widget.position!.inMilliseconds.toDouble() /
                            widget.duration!.inMilliseconds.toDouble())
                        .clamp(0.0, 1.0)
                    : 0.0,
            onChanged: widget.onChanged,
            onChangeEnd: widget.onChangeEnd,
          ),
        ),

        // Time Indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(widget.isDragging
                    ? Duration(
                        milliseconds: (widget.dragValue *
                                (widget.duration?.inMilliseconds ?? 0))
                            .round())
                    : widget.position ?? Duration.zero),
                style: const TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
              Text(
                _formatDuration(widget.duration ?? Duration.zero),
                style: const TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
