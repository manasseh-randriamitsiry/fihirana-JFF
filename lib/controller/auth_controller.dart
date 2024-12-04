import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();
  
  bool get isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email == 'manassehrandriamitsiry@gmail.com';
  }
}
