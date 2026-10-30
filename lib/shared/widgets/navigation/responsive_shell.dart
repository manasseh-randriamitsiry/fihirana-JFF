import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'drawer_widget.dart';

import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';

/// The two shells: a zoom drawer on a phone, a pinned panel from 800px up.
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
    final AppSurfaces s = AppSurfaces.of(context);
    final width = MediaQuery.sizeOf(context).width;

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
            shellController.toggleDrawer();
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
          borderRadius: AppScale.radiusSurface,
          showShadow: true,
          angle: -12.0,
          menuBackgroundColor: s.paper,
          slideWidth: math.min(width * 0.85, AppScale.drawerWidth + 40),
          mainScreenTapClose: true,
          openCurve: AppScale.easeOut,
          closeCurve: AppScale.easeInOut,
        ),
      );
    }

    // Tablet/Desktop Layout: only the drawer-enabled flag needs to rebuild.
    return Obx(() {
      final shouldShowDrawer = shellController.isDrawerEnabled.value;

      return Scaffold(
        backgroundColor: s.paper,
        body: Row(
          children: [
            AnimatedSize(
              duration: AppScale.durLong,
              curve: AppScale.easeOut,
              child: SizedBox(
                width: (shouldShowDrawer && _isDrawerOpen)
                    ? AppScale.drawerWidth
                    : 0,
                child: OverflowBox(
                  minWidth: AppScale.drawerWidth,
                  maxWidth: AppScale.drawerWidth,
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
                  ClipRRect(child: widget.child),
                  if (shouldShowDrawer)
                    Positioned(
                      left: 0,
                      top: AppScale.space96 +
                          AppScale.space40 +
                          AppScale.space12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDrawerOpen = !_isDrawerOpen;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppScale.space4,
                              vertical: AppScale.space12),
                          decoration: BoxDecoration(
                            color: s.sheet,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(AppScale.radiusRow),
                              bottomRight: Radius.circular(AppScale.radiusRow),
                            ),
                            border: Border.all(
                                color: s.ruleFirm, width: AppScale.ruleHair),
                          ),
                          child: Icon(
                            _isDrawerOpen
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            color: s.ink,
                            size: AppScale.iconLg,
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
    });
  }
}
