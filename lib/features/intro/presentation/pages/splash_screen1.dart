import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:fihirana/features/intro/presentation/controllers/splash_controller.dart';

import 'pages/language_selection_page.dart';
import 'pages/welcome_page.dart';
import 'pages/terms_page.dart';

class SplashScreen1 extends StatelessWidget {
  const SplashScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controllers if not already initialized
    Get.put(SplashController());

    final splashController = SplashController.to;
    final pages = [
      const LanguageSelectionPage(),
      const WelcomePage(),
      const TermsPage(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && splashController.currentPage.value > 0) {
          splashController.liquidController.animateToPage(
              page: splashController.currentPage.value - 1, duration: 600);
        }
      },
      child: Scaffold(
        body: LiquidSwipe(
          pages: pages,
          liquidController: splashController.liquidController,
          onPageChangeCallback: (activePageIndex) {
            splashController.updatePage(activePageIndex);

            // Prevent going forward from the last page (terms page)
            if (activePageIndex >= 2) {
              Future.delayed(const Duration(milliseconds: 100), () {
                if (splashController.currentPage.value > 2) {
                  splashController.liquidController.jumpToPage(page: 2);
                }
              });
            }
          },
          waveType: WaveType.liquidReveal,
          enableLoop: false,
          slideIconWidget: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          positionSlideIcon: 0.2,
          enableSideReveal: true,
          ignoreUserGestureWhileAnimating: true,
          disableUserGesture: false,
        ),
      ),
    );
  }
}