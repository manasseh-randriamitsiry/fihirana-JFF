import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SuccessCheckAnimation extends StatelessWidget {
  final double size;
  final Color color;

  const SuccessCheckAnimation({
    super.key,
    this.size = 100,
    this.color = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circle background scaling up
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha:0.1),
            ),
          )
              .animate()
              .scale(
                duration: 400.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 200.ms),

          // Checkmark icon scaling and fading in
          Icon(
            Icons.check_rounded,
            color: color,
            size: size * 0.6,
          )
              .animate(delay: 200.ms)
              .scale(
                duration: 400.ms,
                curve: Curves.elasticOut,
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
              )
              .fadeIn(duration: 200.ms),
        ],
      ),
    );
  }
}
