import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/core/utils/translation_service.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';

class SnackbarStyles {
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color infoColor = Colors.blue;
  static const Color warningColor = Colors.orange;
  static const Color textColor = Colors.white;
  static const SnackPosition defaultPosition = SnackPosition.BOTTOM;
  static const Duration defaultDuration = Duration(seconds: 3);
  static const double defaultBorderRadius = AppDimensions.radiusSm;
  static const EdgeInsets defaultMargin = EdgeInsets.all(AppDimensions.md);
}

class SnackbarConfig {
  final String title;
  final String message;
  final Color backgroundColor;
  final Color colorText;
  final SnackPosition snackPosition;
  final Duration duration;
  final double borderRadius;
  final EdgeInsets margin;
  final IconData? icon;
  final bool showProgressIndicator;
  final Widget? mainButton;

  const SnackbarConfig({
    required this.title,
    required this.message,
    required this.backgroundColor,
    this.colorText = SnackbarStyles.textColor,
    this.snackPosition = SnackbarStyles.defaultPosition,
    this.duration = SnackbarStyles.defaultDuration,
    this.borderRadius = SnackbarStyles.defaultBorderRadius,
    this.margin = SnackbarStyles.defaultMargin,
    this.icon,
    this.showProgressIndicator = false,
    this.mainButton,
  });
}

class CustomSnackbar {
  static void show(SnackbarConfig config) {
    Get.snackbar(
      config.title,
      config.message,
      backgroundColor: config.backgroundColor,
      colorText: config.colorText,
      snackPosition: config.snackPosition,
      duration: config.duration,
      borderRadius: config.borderRadius,
      margin: config.margin,
      icon: config.icon != null
          ? Icon(config.icon, color: config.colorText)
          : null,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      animationDuration: const Duration(milliseconds: 300),
      barBlur: 10,
      overlayBlur: 0,
      showProgressIndicator: config.showProgressIndicator,
      mainButton: config.mainButton != null
          ? TextButton(
              onPressed: () => Get.closeCurrentSnackbar(),
              child: config.mainButton!,
            )
          : null,
    );
  }

  static void success({
    required String message,
    String? title,
    Duration? duration,
    IconData? icon,
    Widget? mainButton,
  }) async {
    final translationService = TranslationService();
    show(SnackbarConfig(
      title: title ??
          await translationService.translate(
              text: 'Success', sourceLanguage: 'en', targetLanguage: 'en'),
      message: message,
      backgroundColor: SnackbarStyles.successColor,
      duration: duration ?? SnackbarStyles.defaultDuration,
      icon: icon ?? Icons.check_circle,
      mainButton: mainButton,
    ));
  }

  static void error({
    required String message,
    String? title,
    Duration? duration,
    IconData? icon,
    Widget? mainButton,
  }) async {
    final translationService = TranslationService();
    show(SnackbarConfig(
      title: title ??
          await translationService.translate(
              text: 'Error', sourceLanguage: 'en', targetLanguage: 'en'),
      message: message,
      backgroundColor: SnackbarStyles.errorColor,
      duration: duration ?? const Duration(seconds: 5), // Longer for errors
      icon: icon ?? Icons.error,
      mainButton: mainButton,
    ));
  }

  static void info({
    required String message,
    String? title,
    Duration? duration,
    IconData? icon,
    Widget? mainButton,
  }) async {
    final translationService = TranslationService();
    show(SnackbarConfig(
      title: title ??
          await translationService.translate(
              text: 'Info', sourceLanguage: 'en', targetLanguage: 'en'),
      message: message,
      backgroundColor: SnackbarStyles.infoColor,
      duration: duration ?? SnackbarStyles.defaultDuration,
      icon: icon ?? Icons.info,
      mainButton: mainButton,
    ));
  }

  static void warning({
    required String message,
    String? title,
    Duration? duration,
    IconData? icon,
    Widget? mainButton,
  }) async {
    final translationService = TranslationService();
    show(SnackbarConfig(
      title: title ??
          await translationService.translate(
              text: 'Warning', sourceLanguage: 'en', targetLanguage: 'en'),
      message: message,
      backgroundColor: SnackbarStyles.warningColor,
      duration: duration ?? SnackbarStyles.defaultDuration,
      icon: icon ?? Icons.warning,
      mainButton: mainButton,
    ));
  }

  static void custom({
    required String title,
    required String message,
    required Color backgroundColor,
    Color? textColor,
    Duration? duration,
    IconData? icon,
    Widget? mainButton,
    SnackPosition? position,
  }) {
    show(SnackbarConfig(
      title: title,
      message: message,
      backgroundColor: backgroundColor,
      colorText: textColor ?? SnackbarStyles.textColor,
      duration: duration ?? SnackbarStyles.defaultDuration,
      icon: icon,
      mainButton: mainButton,
      snackPosition: position ?? SnackbarStyles.defaultPosition,
    ));
  }

  static void loading({
    required String message,
    String? title,
    Duration? duration,
  }) async {
    final translationService = TranslationService();
    show(SnackbarConfig(
      title: title ??
          await translationService.translate(
              text: 'Loading', sourceLanguage: 'en', targetLanguage: 'en'),
      message: message,
      backgroundColor: SnackbarStyles.infoColor,
      showProgressIndicator: true,
      duration: duration ?? const Duration(seconds: 10),
      icon: Icons.hourglass_empty,
    ));
  }

  static void dismiss() {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
  }
}
