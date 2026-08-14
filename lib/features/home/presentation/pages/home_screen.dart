import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:fihirana/features/settings/presentation/widgets/update_checker_widget.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'accueil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _notFirstTime();

    // Enable drawer when entering Home Screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ShellController>().setDrawerEnabled(true);
    });
  }

  Future<void> _notFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
  }

  @override
  Widget build(BuildContext context) {
    return UpdateCheckerWidget(
      child: AccueilScreen(
        openDrawer: () {
          Get.find<ShellController>().toggleDrawer();
        },
        showMenuButton: true,
      ),
    );
  }
}

class HomeController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void toggleDrawer() => Get.find<ShellController>().toggleDrawer();
}
