import 'package:fihirana/screen/accueil/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../controller/language_controller.dart';

class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({super.key});

  @override
  _SplashScreen1State createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1> {
  final TextEditingController _usernameController = TextEditingController();
  bool _agreementAccepted = false;
  int _currentPage = 0;

  // Language selection state variables
  late final LanguageController languageController;
  Locale? selectedLocale;

  @override
  void initState() {
    super.initState();
    _checkAgreementStatus();

    // Initialize language controller
    languageController = Get.find<LanguageController>();
    selectedLocale = languageController.currentLocaleValue;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Widget _buildCard({
    required Widget child,
    EdgeInsets? padding,
    Color? color,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _saveAndProceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenLanguageSelection', true);
    // Move to the next page after language selection
    setState(() {
      _currentPage = 1;
    });
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
    final username = prefs.getString('username') ?? '';
    final hasSelectedLanguage = prefs.getString('selected_language') != null;

    // If user has agreed to terms, entered username, and selected language, go directly to home
    if (hasAgreed && username.isNotEmpty && hasSelectedLanguage) {
      Get.offAll(() => const HomeScreen());
    }
  }

  Widget _buildLanguageOptions(AppLocalizations l10n) {
    return _buildCard(
      color: Colors.white.withOpacity(0.9),
      child: Column(
        children: [
          for (final locale in languageController.supportedLocales)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () async {
                  setState(() {
                    selectedLocale = locale;
                  });
                  languageController.changeLanguage(locale);
                  // Automatically proceed to the next page after language selection
                  await _saveAndProceed();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selectedLocale?.languageCode == locale.languageCode
                        ? Colors.orange.shade100
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selectedLocale?.languageCode == locale.languageCode
                          ? Colors.orange.shade300
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        languageController.getLanguageFlag(locale),
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          languageController.getLanguageName(locale),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: selectedLocale?.languageCode ==
                                    locale.languageCode
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: selectedLocale?.languageCode ==
                                    locale.languageCode
                                ? Colors.orange.shade800
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (selectedLocale?.languageCode == locale.languageCode)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
    final l10n = AppLocalizations.of(context)!;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final pages = [
      // Simplified Page 1: Language Selection
      Container(
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF3E0),
              Color(0xFFFFE0B2),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.language,
                    size: 60,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  l10n.chooseLanguage,
                  style: const TextStyle(
                    fontSize: 24.0,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildLanguageOptions(l10n),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      // Simplified Page 2: Welcome
      Container(
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFBBDEFB),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.music_note,
                    size: 60,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 30),
                _buildCard(
                  child: Column(
                    children: [
                      Text(
                        l10n.splashScreenTitle,
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        l10n.splashScreenSubtitle,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => setState(() => _currentPage = 2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
      // Simplified Page 3: Terms
      Container(
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9),
              Color(0xFFC8E6C9),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                Text(
                  l10n.termsAndConditions,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.agreement,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAgreementItem(l10n.term1),
                      const SizedBox(height: 12),
                      _buildAgreementItem(l10n.term2),
                      const SizedBox(height: 20),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _agreementAccepted = !_agreementAccepted;
                          });
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: _agreementAccepted ? Colors.green : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _agreementAccepted ? Colors.green : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _agreementAccepted ? Colors.green : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: _agreementAccepted
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.acceptTerms,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: TextField(
                    controller: _usernameController,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    decoration: InputDecoration(
                      labelText: l10n.enterYourName,
                      labelStyle: const TextStyle(color: Colors.green, fontSize: 15),
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.green),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _agreementAccepted
                        ? () async {
                            await _handleUsernameSubmit();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _agreementAccepted ? Colors.green : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.continueText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
      body: pages[_currentPage],
    );
  }

  Widget _buildAgreementItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
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
