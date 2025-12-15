import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
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
    final colorController = Get.find<ColorController>();

    final buttonStyle = _getButtonStyle(colorController);
    final buttonSize = _getButtonSize();

    Widget buttonChild = _buildButtonChild();

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

  ButtonStyle _getButtonStyle(ColorController colorController) {
    final baseStyle = ElevatedButton.styleFrom(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
    );

    switch (type) {
      case AppButtonType.primary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(
            isDisabled ? Colors.grey : colorController.primaryColor.value,
          ),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        );

      case AppButtonType.secondary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(
            isDisabled ? Colors.grey : Colors.white,
          ),
          foregroundColor: WidgetStateProperty.all(
            isDisabled ? Colors.grey : colorController.primaryColor.value,
          ),
          side: WidgetStateProperty.all(
            BorderSide(color: colorController.primaryColor.value),
          ),
        );

      case AppButtonType.danger:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(
            isDisabled ? Colors.grey : Colors.red,
          ),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        );

      case AppButtonType.success:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(
            isDisabled ? Colors.grey : Colors.green,
          ),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        );

      case AppButtonType.outline:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.all(
            isDisabled ? Colors.grey : colorController.primaryColor.value,
          ),
          side: WidgetStateProperty.all(
            BorderSide(color: colorController.primaryColor.value),
          ),
          elevation: WidgetStateProperty.all(0),
        );
    }
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

  Widget _buildButtonChild() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
