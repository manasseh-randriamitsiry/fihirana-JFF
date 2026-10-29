import 'package:flutter/material.dart';
import 'package:fihirana/core/design_system/app_scale.dart';

class IntroCardWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;

  const IntroCardWidget({
    super.key,
    required this.child,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppScale.space24),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppScale.radiusFloat),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
