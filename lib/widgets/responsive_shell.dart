import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/color_controller.dart';
import 'drawer_widget.dart';

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
    return Scaffold(
      backgroundColor: _colorController.drawerColor.value,
      body: Row(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: SizedBox(
              width: _isDrawerOpen ? 300 : 0,
              child: OverflowBox(
                minWidth: 300,
                maxWidth: 300,
                child: DrawerWidget(openDrawer: () {}),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  child: widget.child,
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'drawer_toggle',
                    onPressed: () {
                      setState(() {
                        _isDrawerOpen = !_isDrawerOpen;
                      });
                    },
                    backgroundColor: _colorController.primaryColor.value,
                    child: Icon(
                      _isDrawerOpen
                          ? Icons.keyboard_double_arrow_left
                          : Icons.keyboard_double_arrow_right,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
