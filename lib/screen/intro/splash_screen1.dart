import 'package:dots_indicator/dots_indicator.dart';
import 'package:fihirana/screen/accueil/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../controller/color_controller.dart';
import '../../utility/screen_util.dart';

class SplashScreen1 extends StatefulWidget {
  @override
  _SplashScreen1State createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _agreementAccepted = false;
  late AnimationController _balloonController;
  late Animation<double> _balloonAnimation;

  @override
  void initState() {
    super.initState();
    _checkAgreementStatus();
    _balloonController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _balloonAnimation = Tween<double>(
      begin: -60.0,
      end: 60.0,
    ).animate(CurvedAnimation(
      parent: _balloonController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _balloonController.dispose();
    super.dispose();
  }

  Widget _buildFloatingBalloon(double screenWidth) {
    return AnimatedBuilder(
      animation: _balloonAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _balloonAnimation.value),
          child: SizedBox(
            width: screenWidth * 0.5,
            height: screenWidth * 0.5,
            child: SvgPicture.asset(
              "assets/images/balloon.svg",
              alignment: Alignment.center,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleUsernameSubmit() async {
    // Trim whitespace from the username
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      Get.snackbar(
        'Olana',
        'Mampidira anarana azafady',
        snackPosition: SnackPosition.BOTTOM,
      );
      return; // Stop execution if username is empty
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      Get.offAll(() => HomeScreen());
    } catch (e) {
      print('Error saving username: $e');
      Get.snackbar(
        'Olana',
        'Tsy tafiditra ny anarana',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _checkAgreementStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAgreed = prefs.getBool('has_agreed_to_terms') ?? false;

    // Check if the user has agreed AND the username is not empty
    if (hasAgreed && _usernameController.text.trim().isNotEmpty) {
      Get.offAll(() => HomeScreen());
    }
  }

  static const TextStyle greyStyle =
      TextStyle(fontSize: 40.0, color: Colors.grey);
  static const TextStyle whiteStyle =
      TextStyle(fontSize: 40.0, color: Colors.white);
  static const TextStyle boldStyle = TextStyle(
    fontSize: 40.0,
    color: Colors.black,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle descriptionGreyStyle = TextStyle(
    color: Colors.grey,
    fontSize: 14.0,
  );
  static const TextStyle descriptionWhiteStyle = TextStyle(
    color: Colors.white,
    fontSize: 14.0,
  );
  final ColorController _colorController = Get.find<ColorController>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final backgroundColor = _colorController.backgroundColor.value;
    bool _isTablet = isTablet(context);
    final pages = [
      SizedBox(
        height: screenHeight,
        child: Container(
          color: Colors.yellowAccent.shade700,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: _buildFloatingBalloon(screenWidth),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        "Fihirana jesosy famonjena fahamarinantsika",
                        style: boldStyle,
                      ),
                      SizedBox(height: 20.0),
                      Text(
                        "Miderà an'i Jehovah fa tsara Izy",
                        style: descriptionGreyStyle,
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: dotsWidget(
                  active: 0,
                  number: 3,
                ),
              ),
              const SkipWidget()
            ],
          ),
        ),
      ),
      SizedBox(
        height: screenHeight,
        child: Container(
          color: Colors.blue,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: _buildFloatingBalloon(screenWidth),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 30.0),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Miarahaba anao:",
                        style: boldStyle,
                      ),
                      SizedBox(height: 20.0),
                      Text(
                        "Ity fihirana ity dia fihirana natao hoan'ny fiangonana Jesosy Famonjena fahamarinantsika\n. "
                        "Natao izao mba hanamora kokoa ny fiderana an'Andriamanitra\n. Raha te-hampiditra na hanova hira ianao dia mila compte Google, ny hira nampidirinao ihany no azonao fafana\n",
                        style: descriptionWhiteStyle,
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: dotsWidget(
                  active: 1,
                  number: 3,
                ),
              ),
              const SkipWidget()
            ],
          ),
        ),
      ),
      SizedBox(
        height: screenHeight,
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: _buildFloatingBalloon(screenWidth),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Column(
                          children: [
                            Text(
                              "Fanekena:",
                              style: boldStyle,
                            ),
                            SizedBox(height: 20.0),
                            Column(
                              children: [
                                const Text(
                                  "Izaho dia manaiky fa:",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 10.0),
                                const Text(
                                  "1. Tsy hampiasa ny application amin'ny fomba ratsy\n"
                                  "2. Tsy hampiditra hira tsy mifanaraka amin'ny fivavahana JFF  \n",
                                ),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _agreementAccepted,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _agreementAccepted = value ?? false;
                                        });
                                      },
                                      activeColor: Colors.blue,
                                    ),
                                    const Expanded(
                                      child: Text(
                                        "Ekeko ireo fepetra ireo",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 20.0),
                            TextField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Ampidiro ny anaranao',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      25.0), // Adjust the radiusas needed
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _agreementAccepted
                                    ? _handleUsernameSubmit
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 5,
                                  shadowColor: Colors.black.withOpacity(0.5),
                                ),
                                child: const Text(
                                  "Tohizana",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: dotsWidget(
                  active: 2,
                  number: 3,
                ),
              ),
              const SkipWidget()
            ],
          ),
        ),
      ),
    ];

    return Scaffold(
      body: LiquidSwipe(
        pages: pages,
        enableLoop: false,
        fullTransitionValue: 500,
        enableSideReveal: false,
        waveType: WaveType.liquidReveal,
        positionSlideIcon: 0.8,
      ),
    );
  }
}

class dotsWidget extends StatelessWidget {
  final int active;
  final int number;
  const dotsWidget({
    required this.active,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return DotsIndicator(
      dotsCount: number,
      position: active,
      decorator: DotsDecorator(
        size: const Size.square(9.0),
        activeSize: const Size(18.0, 9.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
      ),
    );
  }
}

class SkipWidget extends StatelessWidget {
  const SkipWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Material(
          //   color: Colors.transparent,
          //   child: InkWell(
          //     onTap: () {
          //       Get.offAll(() => HomeScreen());
          //     },
          //     borderRadius: BorderRadius.circular(30),
          //     child: Container(
          //       padding:
          //           const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          //       decoration: BoxDecoration(
          //         border: Border.all(color: Colors.grey.withOpacity(0.5)),
          //         borderRadius: BorderRadius.circular(30),
          //       ),
          //       child: Row(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           Text(
          //             'Dinganina',
          //             style: TextStyle(
          //               color: Colors.grey[600],
          //               fontSize: 16,
          //               fontWeight: FontWeight.w500,
          //             ),
          //           ),
          //           const SizedBox(width: 8),
          //           Icon(
          //             Icons.skip_next_rounded,
          //             color: Colors.grey[600],
          //             size: 20,
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
