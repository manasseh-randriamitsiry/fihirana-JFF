import 'dart:math';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

bool isTablet(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final size = mediaQuery.size;
  final diagonal = sqrt(size.width * size.width + size.height * size.height);
  final isTablet = diagonal > 1100.0;
  return isTablet;
}

double getScreenWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

Color? getTextTheme(BuildContext context) {
  return Theme.of(context).textTheme.bodyLarge?.color;
}

ThemeData getTheme(BuildContext context) {
  final theme = Theme.of(context);
  return theme;
}

double getScreenHeight(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

double getContainerWidth(BuildContext context) {
  return getScreenWidth(context) - 50;
}

double getContainerHeight(BuildContext context) {
  return getScreenHeight(context) - 50;
}

double getContainerHeightWithAppBar(BuildContext context) {
  return getScreenHeight(context) - 100;
}

double getContainerHeightWithAppBarAndFooter(BuildContext context) {
  return getScreenHeight(context) - 150;
}

double getContainerHeightWithAppBarAndFooterAndTabBar(BuildContext context) {
  return getScreenHeight(context) - 200;
}

double getContainerHeightWithAppBarAndTabBar(BuildContext context) {
  return getScreenHeight(context) - 150;
}

double getContainerHeightWithFooter(BuildContext context) {
  return getScreenHeight(context) - 100;
}

double getContainerHeightWithTabBar(BuildContext context) {
  return getScreenHeight(context) - 100;
}

double getContainerHeightWithTabBarAndFooter(BuildContext context) {
  return getScreenHeight(context) - 150;
}

double getContainerHeightWithTabBarAndFooterAndAppBar(BuildContext context) {
  return getScreenHeight(context) - 200;
}

double getContainerHeightWithTabBarAndAppBar(BuildContext context) {
  return getScreenHeight(context) - 150;
}

void getHaptics() async {
  HapticFeedback.lightImpact();
}

void openDrawer(BuildContext context) {
  if (ZoomDrawer.of(context)!.isOpen()) {
    ZoomDrawer.of(context)!.close();
  } else {
    ZoomDrawer.of(context)!.open();
  }
}

void closeDrawer(BuildContext context) {
  ZoomDrawer.of(context)!.close();
}

void showDialogWidget(BuildContext context,
    {required String title,
    required String content,
    required String buttonText}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: Text(buttonText),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void showSnackbarSuccessMessage(
    {required String title, required String message}) {
  Get.snackbar(
    title,
    message,
    backgroundColor: Colors.green.withValues(alpha: 0.2),
    colorText: Colors.white,
    icon: const Icon(Icons.check, color: Colors.green),
  );
}

void showSnackbarErrorMessage(
    {required String title, required String message}) {
  Get.snackbar(
    title,
    message,
    backgroundColor: Colors.red.withValues(alpha: 0.2),
    colorText: Colors.white,
    icon: const Icon(Icons.error_outline, color: Colors.red),
  );
}
