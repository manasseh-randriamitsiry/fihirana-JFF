import 'package:get/get.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

class ShellController extends GetxController {
  final RxBool isDrawerEnabled = false.obs;
  final RxString currentRoute = ''.obs;
  final zoomDrawerController = ZoomDrawerController();

  void setDrawerEnabled(bool enabled) {
    isDrawerEnabled.value = enabled;
  }

  void toggleDrawer() {
    zoomDrawerController.toggle?.call();
  }
}
