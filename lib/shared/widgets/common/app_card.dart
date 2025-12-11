import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';

enum AppCardType {
  elevated,
  outlined,
  filled,
}

class AppCard extends StatelessWidget {
  final Widget child;
  final AppCardType type;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool useThemeColors;

  const AppCard({
    super.key,
    required this.child,
    this.type = AppCardType.elevated,
    this.padding,
    this.margin,
    this.elevation,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.onTap,
    this.useThemeColors = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = useThemeColors ? Get.find<ColorController>() : null;

    final cardWidget = Card(
      elevation: elevation ?? _getDefaultElevation(),
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: backgroundColor ?? _getBackgroundColor(colorController),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? AppDimensions.radiusMd),
        side: _getBorder(colorController),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? AppDimensions.radiusMd),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppDimensions.md),
          child: child,
        ),
      ),
    );

    return cardWidget;
  }

  double _getDefaultElevation() {
    switch (type) {
      case AppCardType.elevated:
        return 4.0;
      case AppCardType.outlined:
        return 0.0;
      case AppCardType.filled:
        return 2.0;
    }
  }

  Color? _getBackgroundColor(ColorController? colorController) {
    if (backgroundColor != null) return backgroundColor;

    switch (type) {
      case AppCardType.elevated:
        return colorController?.backgroundColor.value ?? Colors.white;
      case AppCardType.outlined:
        return Colors.transparent;
      case AppCardType.filled:
        return colorController?.backgroundColor.value.withValues(alpha: 0.05) ?? Colors.grey.shade50;
    }
  }

  BorderSide _getBorder(ColorController? colorController) {
    if (borderColor != null) {
      return BorderSide(color: borderColor!, width: 1.0);
    }

    switch (type) {
      case AppCardType.elevated:
        return BorderSide.none;
      case AppCardType.outlined:
        return BorderSide(
          color: colorController?.primaryColor.value.withValues(alpha: 0.3) ?? Colors.grey.shade300,
          width: 1.0,
        );
      case AppCardType.filled:
        return BorderSide.none;
    }
  }
}