import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../accueil/home_screen.dart';
import '../../l10n/app_localizations.dart';

class SplashScreenAuthenticated extends StatefulWidget {
  const SplashScreenAuthenticated({super.key});

  @override
  SplashScreenAuthenticatedState createState() =>
      SplashScreenAuthenticatedState();
}

class SplashScreenAuthenticatedState extends State<SplashScreenAuthenticated> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      Get.offAll(() => const HomeScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/splash.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.only(top: screenHeight / 4),
                      alignment: Alignment.topCenter,
                      child: Text(
                        l10n.appTitleShort,
                        style: const TextStyle(
                            fontSize: 70.0,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/icon.png',
                        width: 200, // Fixed width instead of screen percentage
                        height: 200,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
