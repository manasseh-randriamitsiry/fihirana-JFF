import 'package:flutter/material.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';
import 'package:fihirana/core/utils/screen_util.dart';

enum AppButtonType {
  primary,
  secondary,
  danger,
  success,
  outline,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle(context);
    final buttonSize = _getButtonSize();

    Widget buttonChild = _buildButtonChild(_foregroundColor(context));

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _getEffectiveOnPressed(),
          style: buttonStyle.copyWith(
            minimumSize: WidgetStateProperty.all(buttonSize),
          ),
          child: buttonChild,
        ),
      );
    }

    return ElevatedButton(
      onPressed: _getEffectiveOnPressed(),
      style: buttonStyle.copyWith(
        minimumSize: WidgetStateProperty.all(buttonSize),
      ),
      child: buttonChild,
    );
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final disabledBackground = colors.onSurface.withValues(alpha: 0.12);
    final baseStyle = ElevatedButton.styleFrom(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
    );

    switch (type) {
      case AppButtonType.primary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(
            isDisabled ? disabledBackground : colors.primary,
          ),
          foregroundColor: WidgetStateProperty.all(_foregroundColor(context)),
        );

      case AppButtonType.secondary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(
            isDisabled ? disabledBackground : colors.surface,
          ),
          foregroundColor: WidgetStateProperty.all(
            _foregroundColor(context),
          ),
          side: WidgetStateProperty.all(
            BorderSide(color: colors.outline),
          ),
        );

      case AppButtonType.danger:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(
            isDisabled ? disabledBackground : colors.error,
          ),
          foregroundColor: WidgetStateProperty.all(_foregroundColor(context)),
        );

      case AppButtonType.success:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(
            isDisabled ? disabledBackground : colors.secondary,
          ),
          foregroundColor: WidgetStateProperty.all(_foregroundColor(context)),
        );

      case AppButtonType.outline:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.all(
            _foregroundColor(context),
          ),
          side: WidgetStateProperty.all(
            BorderSide(color: colors.primary),
          ),
          elevation: WidgetStateProperty.all(0),
        );
    }
  }

  Color _foregroundColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (isDisabled) return colors.onSurfaceVariant;

    return switch (type) {
      AppButtonType.primary => colors.onPrimary,
      AppButtonType.secondary || AppButtonType.outline => colors.primary,
      AppButtonType.danger => colors.onError,
      AppButtonType.success => colors.onSecondary,
    };
  }

  Size _getButtonSize() {
    switch (size) {
      case AppButtonSize.small:
        return const Size(80, 36);
      case AppButtonSize.medium:
        return const Size(120, 44);
      case AppButtonSize.large:
        return const Size(160, 52);
    }
  }

  Widget _buildButtonChild(Color foregroundColor) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }

  VoidCallback? _getEffectiveOnPressed() {
    if (isDisabled || isLoading) return null;
    if (onPressed == null) return null;
    return () {
      getHaptics();
      onPressed!();
    };
  }
}
