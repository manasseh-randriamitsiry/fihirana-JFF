import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for handling user agreements and terms
class UserAgreementController extends GetxController {
  final RxBool agreementAccepted = false.obs;
  final RxBool termsExpanded = true.obs;

  /// Toggle agreement acceptance
  void toggleAgreement() {
    agreementAccepted.value = !agreementAccepted.value;
  }

  /// Toggle terms expansion
  void toggleTermsExpanded() {
    termsExpanded.value = !termsExpanded.value;
  }

  /// Check if user has previously agreed to terms
  Future<bool> hasAgreedToTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_agreed_to_terms') ?? false;
  }

  /// Save agreement status
  Future<void> saveAgreementStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_agreed_to_terms', true);
  }
}
