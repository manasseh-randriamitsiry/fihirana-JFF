import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';

class SplashCardWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;

  const SplashCardWidget({
    super.key,
    required this.child,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color ?? colorController.backgroundColor.value.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(25),
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

// Alias for backward compatibility
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
    return SplashCardWidget(
      key: key,
      padding: padding,
      color: color,
      child: child,
    );
  }
}

class FeatureItemWidget extends StatelessWidget {
  final IconData icon;
  final String text;

  const FeatureItemWidget({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorController.primaryColor.value.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colorController.primaryColor.value,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: colorController.textColor.value.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class AgreementItemWidget extends StatelessWidget {
  final String text;

  const AgreementItemWidget({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: colorController.primaryColor.value,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: colorController.primaryColor.value.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

