import 'package:flutter/material.dart';
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
    final colors = Theme.of(context).colorScheme;
    final radius =
        BorderRadius.circular(borderRadius ?? AppDimensions.radiusLg);
    final surfaceColor = backgroundColor ??
        switch (type) {
          AppCardType.elevated => colors.surface,
          AppCardType.outlined => Colors.transparent,
          AppCardType.filled => colors.surfaceContainerLow,
        };
    final side = borderColor != null
        ? BorderSide(color: borderColor!)
        : type == AppCardType.outlined
            ? BorderSide(color: colors.outlineVariant)
            : BorderSide.none;

    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Material(
        color: surfaceColor,
        elevation: elevation ?? 0,
        shape: RoundedRectangleBorder(borderRadius: radius, side: side),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppDimensions.md),
            child: child,
          ),
        ),
      ),
    );
  }
}
