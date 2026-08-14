import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Home controller for managing home screen logic
class HomeController extends GetxController {
  final RxBool isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    initializeApp();
    markNotFirstTime();
  }

  /// Initialize app components
  Future<void> initializeApp() async {
    isInitialized.value = true;
  }

  /// Mark that user has opened the app before
  Future<void> markNotFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notFirstTime', true);
  }
}
