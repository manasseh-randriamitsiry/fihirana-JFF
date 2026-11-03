import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';

import 'package:fihirana/core/navigation/shell_controller.dart';

void main() {
  group('ShellController drawer gate', () {
    late ShellController shell;
    late ZoomDrawerController zoom;
    int toggles = 0;
    int closes = 0;

    setUp(() {
      Get.reset();
      toggles = 0;
      closes = 0;
      shell = Get.put(ShellController());
      zoom = shell.zoomDrawerController;
      zoom.toggle = ({bool forceToggle = false}) {
        toggles++;
        return null;
      };
      zoom.close = () {
        closes++;
        return null;
      };
    });

    tearDown(() => Get.reset());

    test('a locked drawer ignores the hamburger and the back gesture', () {
      shell.setDrawerEnabled(false);
      shell.toggleDrawer();
      expect(toggles, 0, reason: 'consent screens must not swipe or back open');
    });

    test('an enabled drawer still toggles', () {
      shell.setDrawerEnabled(true);
      shell.toggleDrawer();
      expect(toggles, 1);
    });

    test('locking pulls an already open phone drawer back in', () {
      shell.setDrawerEnabled(true);
      shell.setDrawerEnabled(false);
      expect(closes, 1);
    });
  });
}
