import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/features/intro/presentation/controllers/splash_controller.dart';

import 'pages/language_selection_page.dart';
import 'pages/terms_page.dart';
import 'pages/welcome_page.dart';

class SplashScreen1 extends StatelessWidget {
  const SplashScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    final splashController = Get.isRegistered<SplashController>()
        ? Get.find<SplashController>()
        : Get.put(SplashController());

    return Obx(
      () => PopScope(
        canPop: splashController.currentPage.value == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && splashController.currentPage.value > 0) {
            splashController.goToPage(splashController.currentPage.value - 1);
          }
        },
        child: Scaffold(
          body: PageView(
            controller: splashController.pageController,
            onPageChanged: splashController.updatePage,
            children: const [
              LanguageSelectionPage(),
              WelcomePage(),
              TermsPage(),
            ],
          ),
        ),
      ),
    );
  }
}
