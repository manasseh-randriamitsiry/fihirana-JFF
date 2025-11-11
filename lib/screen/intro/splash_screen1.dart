import 'package:fihirana/screen/accueil/home_screen.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
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
    with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  bool _agreementAccepted = false;
  late AnimationController _balloonController;
  late AnimationController _fadeController;
  late Animation<double> _balloonAnimation;
  late Animation<double> _fadeAnimation;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _checkAgreementStatus();

    _balloonController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _balloonAnimation = Tween<double>(
      begin: -40.0,
      end: 40.0,
    ).animate(CurvedAnimation(
      parent: _balloonController,
      curve: Curves.easeInOut,
    ));

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _balloonController.dispose();
    _fadeController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Widget _buildFloatingBalloon(double screenWidth) {
    return AnimatedBuilder(
      animation: _balloonAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _balloonAnimation.value),
          child: Neumorphic(
            style: NeumorphicStyle(
              depth: 15,
              intensity: 0.8,
              boxShape: const NeumorphicBoxShape.circle(),
              lightSource: LightSource.topLeft,
            ),
            child: Container(
              width: screenWidth * 0.4,
              height: screenWidth * 0.4,
              padding: const EdgeInsets.all(20),
              child: SvgPicture.asset(
                "assets/images/balloon.svg",
                alignment: Alignment.center,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNeumorphicCard({
    required Widget child,
    EdgeInsets? padding,
    Color? color,
  }) {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: 10,
        intensity: 0.7,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(25)),
        color: color,
      ),
      padding: padding ?? const EdgeInsets.all(24),
      child: child,
    );
  }

  Future<void> _handleUsernameSubmit() async {
    print('Button pressed! Agreement: $_agreementAccepted');

    final username = _usernameController.text.trim();
    print('Username entered: "$username"');

    if (username.isEmpty) {
      print('Username is empty, showing error');
      Get.snackbar(
        'Olana',
        'Mampidira anarana azafady',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      print('Saving preferences...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setBool('has_agreed_to_terms', true);
      await prefs.setBool('isFirstTime', false);
      print('Preferences saved, navigating to HomeScreen...');
      Get.offAll(() => const HomeScreen());
      print('Navigation called');
    } catch (e) {
      print('Error saving preferences: $e');
      Get.snackbar(
        'Olana',
        'Tsy tafiditra ny anarana',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
    fontSize: 32.0,
    color: Colors.black87,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: 28.0,
    color: Colors.white,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle descriptionGreyStyle = TextStyle(
    color: Colors.black54,
    fontSize: 16.0,
    height: 1.5,
  );

  static const TextStyle descriptionWhiteStyle = TextStyle(
    color: Colors.white,
    fontSize: 15.0,
    height: 1.6,
  );
  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final pages = [
      // Page 1: Welcome
      NeumorphicBackground(
        child: Container(
          height: screenHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade100,
                Colors.blue.shade100,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  const SizedBox(height: 20),
                  _buildFloatingBalloon(screenWidth),
                  _buildNeumorphicCard(
                    color: Colors.white.withOpacity(0.9),
                    child: Column(
                      children: [
                        Text(
                          "Fihirana jesosy famonjena fahamarinantsika",
                          style: boldStyle.copyWith(fontSize: 26),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16.0),
                        const Text(
                          "Miderà an'i Jehovah fa tsara Izy",
                          style: descriptionGreyStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Neumorphic(
                          style: NeumorphicStyle(
                            depth: 5,
                            intensity: 0.6,
                            boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(15),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.music_note, color: Colors.purple),
                                SizedBox(width: 8),
                                Text(
                                  'Hymnal App',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const ModernDotsIndicator(active: 0, number: 3),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      // Page 2: About
      NeumorphicBackground(
        child: Container(
          height: screenHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.shade300,
                Colors.blue.shade400,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Neumorphic(
                        style: NeumorphicStyle(
                          depth: 12,
                          intensity: 0.8,
                          boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(30),
                          ),
                          color: Colors.white.withOpacity(0.2),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: const Icon(
                          Icons.celebration,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Miarahaba anao!",
                        style: titleStyle,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  _buildNeumorphicCard(
                    color: Colors.white.withOpacity(0.15),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FeatureItem(
                          icon: Icons.church,
                          text: "Fihirana natao hoan'ny fiangonana JFF",
                        ),
                        SizedBox(height: 16),
                        _FeatureItem(
                          icon: Icons.book_outlined,
                          text: "Hanamora kokoa ny fiderana an'Andriamanitra",
                        ),
                        SizedBox(height: 16),
                        _FeatureItem(
                          icon: Icons.cloud_upload,
                          text: "Afaka hampiditra hira vaovao ianao",
                        ),
                        SizedBox(height: 16),
                        _FeatureItem(
                          icon: Icons.account_circle,
                          text: "Mila compte Google ho an'ny fanampiana",
                        ),
                      ],
                    ),
                  ),
                  const ModernDotsIndicator(active: 1, number: 3),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      // Page 3: Get Started
      NeumorphicBackground(
        child: Container(
          height: screenHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.teal.shade100,
                Colors.green.shade100,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    Text(
                      "Fanekena",
                      style: boldStyle.copyWith(
                        fontSize: 32,
                        color: Colors.teal.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    _buildNeumorphicCard(
                      color: Colors.white.withOpacity(0.9),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Neumorphic(
                                style: NeumorphicStyle(
                                  depth: 5,
                                  boxShape: const NeumorphicBoxShape.circle(),
                                  color: Colors.teal.shade50,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.verified_user,
                                  color: Colors.teal.shade700,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "Izaho dia manaiky fa:",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildAgreementItem(
                            "Tsy hampiasa ny application amin'ny fomba ratsy",
                          ),
                          const SizedBox(height: 12),
                          _buildAgreementItem(
                            "Tsy hampiditra hira tsy mifanaraka amin'ny fivavahana JFF",
                          ),
                          const SizedBox(height: 20),
                          NeumorphicButton(
                            onPressed: () {
                              setState(() {
                                _agreementAccepted = !_agreementAccepted;
                              });
                            },
                            style: NeumorphicStyle(
                              depth: _agreementAccepted ? -5 : 5,
                              intensity: 0.7,
                              boxShape: NeumorphicBoxShape.roundRect(
                                BorderRadius.circular(15),
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Neumorphic(
                                  style: NeumorphicStyle(
                                    depth: _agreementAccepted ? -3 : 3,
                                    boxShape: NeumorphicBoxShape.roundRect(
                                      BorderRadius.circular(6),
                                    ),
                                    color: _agreementAccepted
                                        ? Colors.teal
                                        : Colors.grey.shade200,
                                  ),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    child: _agreementAccepted
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 18,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    "Ekeko ireo fepetra ireo",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Neumorphic(
                      style: NeumorphicStyle(
                        depth: -8,
                        intensity: 0.7,
                        boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(25),
                        ),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: _usernameController,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Ampidiro ny anaranao',
                          labelStyle: TextStyle(
                            color: Colors.teal.shade700,
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Colors.teal.shade600,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: NeumorphicButton(
                        onPressed: _agreementAccepted
                            ? () async {
                                await _handleUsernameSubmit();
                              }
                            : null,
                        style: NeumorphicStyle(
                          shape: NeumorphicShape.flat,
                          boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(25),
                          ),
                          depth: _agreementAccepted ? 8 : 3,
                          intensity: 0.7,
                          color: _agreementAccepted
                              ? Colors.teal.shade600
                              : Colors.grey.shade300,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Tohizana",
                              style: TextStyle(
                                fontSize: 18,
                                color: _agreementAccepted
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: _agreementAccepted
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const ModernDotsIndicator(active: 2, number: 3),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: LiquidSwipe(
          pages: pages,
          enableLoop: false,
          fullTransitionValue: 400,
          enableSideReveal: true,
          waveType: WaveType.liquidReveal,
          positionSlideIcon: 0.75,
          onPageChangeCallback: (page) {
            setState(() {
              _currentPage = page;
            });
          },
        ),
      ),
    );
  }

  Widget _buildAgreementItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Neumorphic(
          style: NeumorphicStyle(
            depth: 3,
            boxShape: const NeumorphicBoxShape.circle(),
            color: Colors.teal.shade100,
          ),
          padding: const EdgeInsets.all(6),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.teal.shade600,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class ModernDotsIndicator extends StatelessWidget {
  final int active;
  final int number;

  const ModernDotsIndicator({
    super.key,
    required this.active,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(number, (index) {
        final isActive = index == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Neumorphic(
            style: NeumorphicStyle(
              depth: isActive ? -4 : 4,
              intensity: 0.7,
              boxShape: NeumorphicBoxShape.roundRect(
                BorderRadius.circular(isActive ? 12 : 6),
              ),
              color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            ),
            child: Container(
              width: isActive ? 32 : 12,
              height: 12,
            ),
          ),
        );
      }),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Neumorphic(
          style: NeumorphicStyle(
            depth: 6,
            boxShape: const NeumorphicBoxShape.circle(),
            color: Colors.white.withOpacity(0.3),
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
