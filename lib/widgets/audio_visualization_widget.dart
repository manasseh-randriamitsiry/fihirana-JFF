import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import '../controller/color_controller.dart';
import 'package:get/get.dart';

class AudioVisualizationWidget extends StatefulWidget {
  final bool isPlaying;
  final Color? primaryColor;
  final int barCount;
  final double height;
  final bool showGlow;

  const AudioVisualizationWidget({
    Key? key,
    this.isPlaying = false,
    this.primaryColor,
    this.barCount = 20,
    this.height = 60,
    this.showGlow = true,
  }) : super(key: key);

  @override
  State<AudioVisualizationWidget> createState() => _AudioVisualizationWidgetState();
}

class _AudioVisualizationWidgetState extends State<AudioVisualizationWidget>
    with TickerProviderStateMixin {
  final ColorController _colorController = Get.find<ColorController>();
  late AnimationController _animationController;
  late List<Animation<double>> _barAnimations;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _barAnimations = List.generate(
      widget.barCount,
      (index) => Tween<double>(
        begin: 0.1,
        end: _random.nextDouble() * 0.8 + 0.2,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index / widget.barCount,
            (index + 1) / widget.barCount,
            curve: Curves.easeInOut,
          ),
        ),
      ),
    );

    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _animationController.repeat(reverse: true);
  }

  void _stopAnimation() {
    _animationController.stop();
    _animationController.reset();
  }

  @override
  void didUpdateWidget(AudioVisualizationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor ?? _colorController.primaryColor.value;
    
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              widget.barCount,
              (index) => _buildBar(index, color),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBar(int index, Color color) {
    final animation = _barAnimations[index];
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 3,
      height: widget.height * animation.value,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            color,
            color.withOpacity(0.6),
            color.withOpacity(0.3),
          ],
        ),
        boxShadow: widget.showGlow && animation.value > 0.5
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

class WaveformVisualizationWidget extends StatefulWidget {
  final bool isPlaying;
  final Color? primaryColor;
  final double height;
  final double strokeWidth;

  const WaveformVisualizationWidget({
    Key? key,
    this.isPlaying = false,
    this.primaryColor,
    this.height = 40,
    this.strokeWidth = 2.0,
  }) : super(key: key);

  @override
  State<WaveformVisualizationWidget> createState() => _WaveformVisualizationWidgetState();
}

class _WaveformVisualizationWidgetState extends State<WaveformVisualizationWidget>
    with TickerProviderStateMixin {
  final ColorController _colorController = Get.find<ColorController>();
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(_waveController);

    if (widget.isPlaying) {
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(WaveformVisualizationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _waveController.repeat();
      } else {
        _waveController.stop();
        _waveController.reset();
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor ?? _colorController.primaryColor.value;
    
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _waveAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: WaveformPainter(
              animation: _waveAnimation.value,
              color: color,
              strokeWidth: widget.strokeWidth,
              isPlaying: widget.isPlaying,
            ),
          );
        },
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double animation;
  final Color color;
  final double strokeWidth;
  final bool isPlaying;

  WaveformPainter({
    required this.animation,
    required this.color,
    required this.strokeWidth,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const waveCount = 4;
    const amplitude = 15.0;
    
    for (double x = 0; x <= size.width; x += 2) {
      final normalizedX = x / size.width;
      final wavePhase = normalizedX * waveCount * 2 * pi;
      final animatedPhase = isPlaying ? animation : 0;
      final y = size.height / 2 + 
                amplitude * sin(wavePhase + animatedPhase) * 
                (isPlaying ? 1.0 : 0.3);
      
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CircularVisualizationWidget extends StatefulWidget {
  final bool isPlaying;
  final Color? primaryColor;
  final double size;
  final int circleCount;

  const CircularVisualizationWidget({
    Key? key,
    this.isPlaying = false,
    this.primaryColor,
    this.size = 80,
    this.circleCount = 8,
  }) : super(key: key);

  @override
  State<CircularVisualizationWidget> createState() => _CircularVisualizationWidgetState();
}

class _CircularVisualizationWidgetState extends State<CircularVisualizationWidget>
    with TickerProviderStateMixin {
  final ColorController _colorController = Get.find<ColorController>();
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.circleCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 800 + (index * 100)),
        vsync: this,
      ),
    );

    _animations = List.generate(
      widget.circleCount,
      (index) => Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _controllers[index],
          curve: Curves.easeInOut,
        ),
      ),
    );

    if (widget.isPlaying) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimations() {
    for (final controller in _controllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void didUpdateWidget(CircularVisualizationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor ?? _colorController.primaryColor.value;
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge(_animations),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: List.generate(
              widget.circleCount,
              (index) => _buildCircle(index, color),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCircle(int index, Color color) {
    final animation = _animations[index];
    final angle = (index * 2 * pi) / widget.circleCount;
    final radius = widget.size / 3;
    final centerX = radius * cos(angle);
    final centerY = radius * sin(angle);
    
    return Positioned(
      left: widget.size / 2 + centerX - 6,
      top: widget.size / 2 + centerY - 6,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(animation.value),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(animation.value * 0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class NeumorphicAudioVisualizer extends StatelessWidget {
  final bool isPlaying;
  final String visualizationType;
  final Color? primaryColor;
  final double? height;

  const NeumorphicAudioVisualizer({
    Key? key,
    required this.isPlaying,
    this.visualizationType = 'bars',
    this.primaryColor,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ColorController colorController = Get.find<ColorController>();
    final color = primaryColor ?? colorController.primaryColor.value;
    
    Widget visualization;
    
    switch (visualizationType) {
      case 'waveform':
        visualization = WaveformVisualizationWidget(
          isPlaying: isPlaying,
          primaryColor: color,
          height: height ?? 40,
        );
        break;
      case 'circular':
        visualization = CircularVisualizationWidget(
          isPlaying: isPlaying,
          primaryColor: color,
          size: height != null ? height! * 2 : 80,
        );
        break;
      default:
        visualization = AudioVisualizationWidget(
          isPlaying: isPlaying,
          primaryColor: color,
          height: height ?? 60,
        );
    }
    
    return Neumorphic(
      style: NeumorphicStyle(
        depth: 4,
        intensity: 0.8,
        color: colorController.backgroundColor.value,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: visualization),
      ),
    );
  }
}