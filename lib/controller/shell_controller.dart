import 'package:get/get.dart';

class ShellController extends GetxController {
  final RxBool isDrawerEnabled = false.obs;

  void setDrawerEnabled(bool enabled) {
    isDrawerEnabled.value = enabled;
  }
}
