import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// A reusable widget for displaying Rive animations with error handling and fallback support.
class RiveAnimationWidget extends StatefulWidget {
  /// Path to the Rive animation file in assets
  final String assetPath;

  /// Optional animation name to play (if the .riv file contains multiple animations)
  final String? animationName;

  /// Optional state machine name to use
  final String? stateMachineName;

  /// Whether the animation should loop
  final bool loop;

  /// Whether the animation should auto-play
  final bool autoplay;

  /// Fit mode for the animation
  final BoxFit fit;

  /// Alignment of the animation within its bounds
  final Alignment alignment;

  /// Fallback widget to display if animation fails to load
  final Widget? fallback;

  /// Callback when animation is loaded successfully
  final VoidCallback? onInit;

  /// Width of the animation container
  final double? width;

  /// Height of the animation container
  final double? height;

  const RiveAnimationWidget({
    super.key,
    required this.assetPath,
    this.animationName,
    this.stateMachineName,
    this.loop = true,
    this.autoplay = true,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.fallback,
    this.onInit,
    this.width,
    this.height,
  });

  @override
  State<RiveAnimationWidget> createState() => _RiveAnimationWidgetState();
}

class _RiveAnimationWidgetState extends State<RiveAnimationWidget> {
  Artboard? _artboard;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  Future<void> _loadRiveFile() async {
    try {
      final data = await RiveFile.asset(widget.assetPath);
      final artboard = data.mainArtboard;

      // Add animation controller or state machine
      if (widget.stateMachineName != null) {
        final controller = StateMachineController.fromArtboard(
          artboard,
          widget.stateMachineName!,
        );
        if (controller != null) {
          artboard.addController(controller);
        }
      } else if (widget.animationName != null) {
        final controller = SimpleAnimation(
          widget.animationName!,
          autoplay: widget.autoplay,
        );
        artboard.addController(controller);
      } else {
        // Use the first animation if no specific animation is specified
        if (artboard.animations.isNotEmpty) {
          final controller = SimpleAnimation(
            artboard.animations.first.name,
            autoplay: widget.autoplay,
          );
          artboard.addController(controller);
        }
      }

      if (mounted) {
        setState(() {
          _artboard = artboard;
        });
        widget.onInit?.call();
      }
    } catch (e) {
      debugPrint('Error loading Rive animation: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error fallback if animation failed to load
    if (_hasError) {
      return widget.fallback ?? _buildDefaultFallback();
    }

    // Show loading state while animation is loading
    if (_artboard == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Display the Rive animation
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Rive(
        artboard: _artboard!,
        fit: widget.fit,
        alignment: widget.alignment,
      ),
    );
  }

  Widget _buildDefaultFallback() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(
        child: Icon(
          Icons.animation,
          size: (widget.width ?? 100) * 0.5,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}

/// A simple Rive animation widget with minimal configuration
class SimpleRiveAnimation extends StatelessWidget {
  final String assetPath;
  final double size;
  final BoxFit fit;

  const SimpleRiveAnimation({
    super.key,
    required this.assetPath,
    this.size = 200,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return RiveAnimationWidget(
      assetPath: assetPath,
      width: size,
      height: size,
      fit: fit,
      loop: true,
      autoplay: true,
    );
  }
}
