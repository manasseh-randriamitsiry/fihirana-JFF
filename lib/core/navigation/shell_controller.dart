import 'package:get/get.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

class ShellController extends GetxController {
  final RxBool isDrawerEnabled = false.obs;
  final RxString currentRoute = ''.obs;
  final zoomDrawerController = ZoomDrawerController();

  void setDrawerEnabled(bool enabled) {
    isDrawerEnabled.value = enabled;
    // Splash, loading and consent screens reach the flag after the phone drawer
    // is already mounted, so it has to be pulled back in rather than merely
    // forbidden from opening again.
    if (!enabled) zoomDrawerController.close?.call();
  }

  void toggleDrawer() {
    if (!isDrawerEnabled.value) return;
    zoomDrawerController.toggle?.call();
  }
}
