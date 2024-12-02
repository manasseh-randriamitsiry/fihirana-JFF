import 'package:dots_indicator/dots_indicator.dart';
import 'package:fihirana/screen/accueil/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Save user info
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', userCredential.user?.displayName ?? '');
      await prefs.setString('email', userCredential.user?.email ?? '');

      Get.offAll(() => const HomeScreen());
    } catch (e) {
      print('Error signing in with Google: $e');
      Get.snackbar(
        'Olana',
        'Tsy nety ny fidirana @Google',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUsernameSubmit() async {
    if (_usernameController.text.trim().isEmpty) {
      Get.snackbar(
        'Olana',
        'Mampidira anarana azafady',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _usernameController.text.trim());
      Get.offAll(() => const HomeScreen());
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
    if (hasAgreed) {
      Get.offAll(() => const HomeScreen());
    }
  }

  Future<void> _saveAgreementAndProceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_agreed_to_terms', true);
    Get.offAll(() => const HomeScreen());
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    bool _isTablet = isTablet(context);
    final pages = [
      SizedBox(
        height: screenHeight,
        child: Container(
          color: Colors.yellowAccent.shade700,
          child: SafeArea(
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
                    number: 4,
                  ),
                ),
                const SkipWidget()
              ],
            ),
          ),
        ),
      ),
      SizedBox(
        height: screenHeight,
        child: Container(
          color: Colors.blue,
          child: SafeArea(
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
                        Text(
                          "Ireo zavatra azo atao:",
                          style: boldStyle,
                        ),
                        SizedBox(height: 20.0),
                        Text(
                          "1. Mijery hira\n"
                          "2. Mapiditra hira vaovao\n"
                          "3. Manova hira\n"
                          "4. Mapiditra hira ho tiana\n"
                          "5. Mapiditra naoty\n"
                          "6. Mamafa hira\n"
                          "7. Mitady hira\n",
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
                    number: 4,
                  ),
                ),
                const SkipWidget()
              ],
            ),
          ),
        ),
      ),
      SizedBox(
        height: screenHeight,
        child: Container(
          color: Colors.white,
          child: SafeArea(
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
                        Text(
                          "Tongasoa!",
                          style: boldStyle,
                        ),
                        SizedBox(height: 20.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30.0),
                          child: Column(
                            children: [
                              const Text(
                                "Frera/Soeur iza no fiantsoana anao ?",
                                style: descriptionGreyStyle,
                              ),
                              SizedBox(height: 20.0),
                              TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Apidiro ny anaranao',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text('Na',
                                  style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed:
                                    _isLoading ? null : _handleGoogleSignIn,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(double.infinity, 50),
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  side: BorderSide(color: Colors.grey),
                                ),
                                icon: Image.asset(
                                  'assets/images/google.png',
                                  height: 24,
                                ),
                                label: Text('Hiditra @ google'),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _handleUsernameSubmit,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(double.infinity, 50),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('Tohizana'),
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
                    number: 4,
                  ),
                ),
                const SkipWidget()
              ],
            ),
          ),
        ),
      ),
      SizedBox(
        height: screenHeight,
        child: Container(
          color: Colors.purple,
          child: SafeArea(
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
                              style: descriptionWhiteStyle,
                            ),
                            const SizedBox(height: 20.0),
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
                            const SizedBox(height: 20.0),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _agreementAccepted
                                    ? _saveAgreementAndProceed
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  "Tohizana",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 20.0),
                  child: dotsWidget(
                    active: 3,
                    number: 4,
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
        enableSideReveal: true,
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
          TextButton(
            onPressed: () {
              Get.offAll(() => const HomeScreen());
            },
            child: Text(
              'dinganina',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
