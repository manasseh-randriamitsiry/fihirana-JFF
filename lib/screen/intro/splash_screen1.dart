import 'package:dots_indicator/dots_indicator.dart';
import 'package:fihirana/screen/accueil/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({super.key});

  @override
  _SplashScreen1State createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
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

    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      Get.snackbar(
        'Olana',
        'Mampidira anarana azafady',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      Get.offAll(() => const HomeScreen());
    } catch (e) {
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

    if (hasAgreed && _usernameController.text.trim().isNotEmpty) {
      Get.offAll(() => const HomeScreen());
    }
  }

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
  late bool isTablet = isTablet;
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
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
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
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
      SingleChildScrollView(
        child: SizedBox(
          height: screenHeight,
          child: Container(
            color: Colors.white,
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: screenHeight * 0.2,
                  child: _buildFloatingBalloon(screenWidth),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Fanekena:",
                            style: boldStyle.copyWith(fontSize: 30.0),
                          ),
                          const SizedBox(height: 10.0),
                          Column(
                            children: [
                              const Text(
                                "Izaho dia manaiky fa:",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5.0),
                              const Text(
                                "1. Tsy hampiasa ny application amin'ny fomba ratsy\n"
                                "2. Tsy hampiditra hira tsy mifanaraka amin'ny fivavahana JFF  \n",
                                style: TextStyle(fontSize: 14),
                              ),
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 0.9,
                                    child: Checkbox(
                                      value: _agreementAccepted,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _agreementAccepted = value ?? false;
                                        });
                                      },
                                      activeColor: Colors.blue,
                                    ),
                                  ),
                                  const Expanded(
                                    child: Text(
                                      "Ekeko ireo fepetra ireo",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Ampidiro ny anaranao',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
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
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                                shadowColor: Colors.black.withOpacity(0.5),
                              ),
                              child: const Text(
                                "Tohizana",
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10.0),
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
  const dotsWidget({super.key,
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
  const SkipWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [

        ],
      ),
    );
  }
}