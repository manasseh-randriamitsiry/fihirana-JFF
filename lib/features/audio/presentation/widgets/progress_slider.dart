import 'package:flutter/material.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/app_typography.dart';

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

  double get _value {
    if (widget.isDragging) return widget.dragValue;
    final duration = widget.duration;
    final position = widget.position;
    if (duration == null || position == null || duration.inMilliseconds <= 0) {
      return 0.0;
    }
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    final shown = widget.isDragging
        ? Duration(
            milliseconds:
                (widget.dragValue * (widget.duration?.inMilliseconds ?? 0))
                    .round())
        : widget.position ?? Duration.zero;

    return Column(
      children: [
        Slider(
          value: _value,
          onChanged: widget.onChanged,
          onChangeEnd: widget.onChangeEnd,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppScale.space8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(shown),
                  style: AppTypography.figure(s,
                      size: AppScale.figureSm, color: s.muted)),
              Text(_formatDuration(widget.duration ?? Duration.zero),
                  style: AppTypography.figure(s,
                      size: AppScale.figureSm, color: s.muted)),
            ],
          ),
        ),
      ],
    );
  }
}
