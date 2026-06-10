import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';

class HomeScreenScaffold extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget> actions;
  final Widget? leading;
  final bool showDrawer;
  final VoidCallback? onDrawerPressed;

  const HomeScreenScaffold({
    super.key,
    required this.child,
    required this.title,
    this.actions = const [],
    this.leading,
    this.showDrawer = false,
    this.onDrawerPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final backgroundColor = colorController.backgroundColor.value;
    final textColor = colorController.textColor.value;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: leading ??
            (showDrawer
                ? IconButton(
                    icon: Icon(Icons.menu,
                        color: colorController.iconColor.value),
                    onPressed: onDrawerPressed,
                  )
                : null),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: actions,
      ),
      body: child,
    );
  }
}
