import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controller/recording_controller.dart';
import '../controller/color_controller.dart';
import '../models/user_recording.dart';

class RecordingPlayerOverlay extends StatefulWidget {
  const RecordingPlayerOverlay({super.key});

  @override
  State<RecordingPlayerOverlay> createState() => _RecordingPlayerOverlayState();
}

class _RecordingPlayerOverlayState extends State<RecordingPlayerOverlay>
    with SingleTickerProviderStateMixin {
  final RecordingController _controller = Get.find<RecordingController>();
  final ColorController _colorController = Get.find<ColorController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!_controller.shouldShowPlayerOverlay()) {
        return const SizedBox.shrink();
      }

      final isMinimized = _controller.isPlayerMinimized.value;
      final recording = _controller.currentRecording.value;

      if (recording == null) return const SizedBox.shrink();

      return Positioned(
        bottom: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.bottomRight,
            child: isMinimized
                ? _buildFab(recording)
                : _buildExpandedCard(recording),
          ),
        ),
      );
    });
  }

  Widget _buildFab(UserRecording recording) {
    return GestureDetector(
      onTap: () => _controller.restorePlayer(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _colorController.primaryColor.value,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress indicator ring
            Obx(() {
              final position = _controller.currentPosition.value.inSeconds;
              final duration = _controller.totalDuration.value.inSeconds;
              final progress = duration > 0 ? position / duration : 0.0;

              return SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                ),
              );
            }),
            // Play/Pause icon
            Obx(() => Icon(
                  _controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                )),
          ],
        ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
  }

  Widget _buildExpandedCard(UserRecording recording) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colorController.backgroundColor.value,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: _colorController.primaryColor.value.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _colorController.primaryColor.value
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.music_note,
                  color: _colorController.primaryColor.value,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recording.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _colorController.textColor.value,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Hymn ${recording.hymnId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _colorController.textColor.value
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon:
                    Icon(Icons.close, color: _colorController.textColor.value),
                onPressed: () => _controller.hidePlayer(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.keyboard_arrow_down,
                    color: _colorController.textColor.value),
                onPressed: () => _controller.minimizePlayer(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Slider
          Obx(() {
            final position = _controller.currentPosition.value;
            final duration = _controller.totalDuration.value;

            return Column(
              children: [
                GestureDetector(
                  onPanUpdate: (details) {
                    final box = context.findRenderObject() as RenderBox;
                    final tapPos = box.globalToLocal(details.globalPosition);
                    final tapValue = (tapPos.dx / box.size.width) * duration.inSeconds;
                    _controller.seekTo(Duration(seconds: tapValue.round().clamp(0, duration.inSeconds)));
                  },
                  onTapUp: (details) {
                    final box = context.findRenderObject() as RenderBox;
                    final tapPos = box.globalToLocal(details.globalPosition);
                    final tapValue = (tapPos.dx / box.size.width) * duration.inSeconds;
                    _controller.seekTo(Duration(seconds: tapValue.round().clamp(0, duration.inSeconds)));
                  },
                  child: SizedBox(
                    height: 40,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _CustomSliderPainter(
                        progress: duration.inSeconds > 0 
                            ? position.inSeconds / duration.inSeconds 
                            : 0.0,
                        primaryColor: _colorController.primaryColor.value,
                        inactiveColor: _colorController.iconColor.value.withValues(alpha: 0.2),
                      ),
                      child: Container(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position.inSeconds),
                        style: TextStyle(
                          fontSize: 10,
                          color: _colorController.textColor.value
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        _formatDuration(duration.inSeconds),
                        style: TextStyle(
                          fontSize: 10,
                          color: _colorController.textColor.value
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 8),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.replay_10,
                    color: _colorController.iconColor.value),
                onPressed: () {
                  final newPos = _controller.currentPosition.value -
                      const Duration(seconds: 10);
                  _controller
                      .seekTo(newPos < Duration.zero ? Duration.zero : newPos);
                },
              ),
              const SizedBox(width: 16),
              Obx(() => GestureDetector(
                    onTap: () {
                      if (_controller.isPlaying.value) {
                        _controller.pausePlayback();
                      } else {
                        _controller.playRecording(recording);
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _colorController.primaryColor.value,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _colorController.primaryColor.value
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _controller.isPlaying.value
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  )),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.forward_10,
                    color: _colorController.iconColor.value),
                onPressed: () {
                  final newPos = _controller.currentPosition.value +
                      const Duration(seconds: 10);
                  _controller.seekTo(newPos);
                },
              ),
            ],
          ),

          // Speed Control (Compact)
          Center(
            child: Obx(() => InkWell(
                  onTap: () {
                    final currentSpeed = _controller.playbackSpeed.value;
                    final newSpeed =
                        currentSpeed >= 2.0 ? 0.5 : currentSpeed + 0.25;
                    _controller.setPlaybackSpeed(newSpeed);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '${_controller.playbackSpeed.value}x',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _colorController.primaryColor.value,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _CustomSliderPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color inactiveColor;

  _CustomSliderPainter({
    required this.progress,
    required this.primaryColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const trackHeight = 2.0;
    const thumbRadius = 6.0;
    final trackY = size.height / 2;

    // Draw inactive track
    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = trackHeight
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(0, trackY),
      Offset(size.width, trackY),
      inactivePaint,
    );

    // Draw active track
    final activePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = trackHeight
      ..strokeCap = StrokeCap.round;
    
    final activeWidth = size.width * progress;
    canvas.drawLine(
      Offset(0, trackY),
      Offset(activeWidth, trackY),
      activePaint,
    );

    // Draw thumb
    final thumbPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(activeWidth, trackY),
      thumbRadius,
      thumbPaint,
    );
  }

  @override
  bool shouldRepaint(_CustomSliderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.inactiveColor != inactiveColor;
  }
}
