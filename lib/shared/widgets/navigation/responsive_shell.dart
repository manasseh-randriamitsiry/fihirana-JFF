import 'package:get/get.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'drawer_widget.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';

import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

class ResponsiveShell extends StatefulWidget {
  final Widget child;

  const ResponsiveShell({super.key, required this.child});

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  bool _isDrawerOpen = true;

  @override
  Widget build(BuildContext context) {
    final shellController = Get.find<ShellController>();
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    if (width < 800) {
      // Phone Layout: Use ZoomDrawer globally. This branch does not depend on
      // any reactive state, so it must not be wrapped in Obx.
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          final navigator = Get.key.currentState;
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
          } else {
            if (shellController.zoomDrawerController.isOpen?.call() ?? false) {
              shellController.toggleDrawer();
            } else {
              shellController.toggleDrawer();
            }
          }
        },
        child: ZoomDrawer(
          controller: shellController.zoomDrawerController,
          style: DrawerStyle.defaultStyle,
          menuScreen: DrawerWidget(
            key: const ValueKey('zoom_drawer'),
            openDrawer: shellController.toggleDrawer,
          ),
          mainScreen: widget.child,
          borderRadius: AppDimensions.radiusXxl,
          showShadow: true,
          angle: -12.0,
          menuBackgroundColor: colorScheme.surface,
          slideWidth: width * 0.85,
          mainScreenTapClose: true,
          openCurve: Curves.fastOutSlowIn,
          closeCurve: Curves.bounceIn,
        ),
      );
    }

    // Tablet/Desktop Layout: only the drawer-enabled flag needs to rebuild.
    return Obx(() {
      final shouldShowDrawer = shellController.isDrawerEnabled.value;

      final mainContent = Scaffold(
        backgroundColor: colorScheme.surface,
        body: Row(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: SizedBox(
                width: (shouldShowDrawer && _isDrawerOpen) ? 300 : 0,
                child: OverflowBox(
                  minWidth: 300,
                  maxWidth: 300,
                  child: DrawerWidget(
                    key: const ValueKey('shell_drawer'),
                    openDrawer: () {},
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    child: widget.child,
                  ),
                  if (shouldShowDrawer)
                    Positioned(
                      left: 0,
                      top: 250,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDrawerOpen = !_isDrawerOpen;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Icon(
                            _isDrawerOpen
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
      return mainContent;
    });
  }
}
