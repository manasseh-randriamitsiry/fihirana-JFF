import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  final RxString username = ''.obs;
  final RxBool isAuthenticated = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username') ?? '';
    username.value = savedUsername;
  }

  Future<void> setUsername(String newUsername) async {
    username.value = newUsername;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newUsername);
  }

  void setAuthenticated(bool authenticated) {
    isAuthenticated.value = authenticated;
  }
}
