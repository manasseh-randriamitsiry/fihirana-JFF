import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../accueil/home_screen.dart';

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
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
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
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: screenHeight / 4),
              alignment: Alignment.topCenter,
              child: const Text(
                "JFF",
                style: TextStyle(
                    fontSize: 70.0,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/icon.png',
                width: screenWidth / 2,
                height: screenHeight / 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
