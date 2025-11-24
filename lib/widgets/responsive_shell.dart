import 'package:get/get.dart';
import '../controller/color_controller.dart';
import '../controller/shell_controller.dart';
import 'drawer_widget.dart';
import 'recording_overlay_manager.dart';

import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

class ResponsiveShell extends StatefulWidget {
  final Widget child;

  const ResponsiveShell({super.key, required this.child});

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  bool _isDrawerOpen = true;
  final ColorController _colorController = Get.find<ColorController>();

  @override
  Widget build(BuildContext context) {
    final shellController = Get.find<ShellController>();

    return Obx(() {
      final width = MediaQuery.of(context).size.width;
      final isMobile = width < 800;

      if (isMobile) {
        // Phone Layout: Use ZoomDrawer globally
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            final navigator = Get.key.currentState;
            if (navigator != null && navigator.canPop()) {
              navigator.pop();
            } else {
              if (shellController.zoomDrawerController.isOpen?.call() ??
                  false) {
                shellController.toggleDrawer();
              } else {
                shellController.toggleDrawer();
              }
            }
          },
          child: NeumorphicBackground(
            child: Stack(
              children: [
                ZoomDrawer(
                  controller: shellController.zoomDrawerController,
                  style: DrawerStyle.defaultStyle,
                  menuScreen: DrawerWidget(
                    key: const ValueKey('zoom_drawer'),
                    openDrawer: shellController.toggleDrawer,
                  ),
                  mainScreen: widget.child,
                  borderRadius: 24.0,
                  showShadow: true,
                  angle: -12.0,
                  menuBackgroundColor: _colorController.drawerColor.value,
                  slideWidth: width * 0.85,
                  mainScreenTapClose: true,
                  openCurve: Curves.fastOutSlowIn,
                  closeCurve: Curves.bounceIn,
                ),
                 // Recording overlay manager for mobile
                 const RecordingOverlayManager(),
              ],
            ),
          ),
        );
      }

      // Tablet/Desktop Layout: Use Row with Side Drawer
      final shouldShowDrawer = shellController.isDrawerEnabled.value;

      return Scaffold(
        backgroundColor: _colorController.drawerColor.value,
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
                            color: _colorController.drawerColor.value,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(2, 0),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isDrawerOpen
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            color: _colorController.iconColor.value,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                   // Recording overlay manager for desktop/tablet
                   const RecordingOverlayManager(),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
