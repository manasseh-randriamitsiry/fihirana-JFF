import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import '../../controller/language_controller.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  final LanguageController languageController = Get.find<LanguageController>();
  Locale? selectedLocale;

  @override
  void initState() {
    super.initState();
    selectedLocale = languageController.currentLocaleValue;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return NeumorphicBackground(
      child: Container(
        height: screenHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade100,
              Colors.pink.shade100,
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
                        boxShape: const NeumorphicBoxShape.circle(),
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.all(25),
                      child: const Icon(
                        Icons.language,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Safidio fiteny",
                      style: TextStyle(
                        fontSize: 32.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Choisissez votre langue\nChoose your language",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16.0,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                _buildLanguageOptions(),
                const ModernDotsIndicator(active: 3, number: 4),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOptions() {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: 10,
        intensity: 0.7,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(25)),
        color: Colors.white.withValues(alpha: 0.9),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          for (final locale in languageController.supportedLocales)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NeumorphicButton(
                onPressed: () {
                  setState(() {
                    selectedLocale = locale;
                  });
                  languageController.changeLanguage(locale);
                },
                style: NeumorphicStyle(
                  depth: selectedLocale?.languageCode == locale.languageCode ? -5 : 5,
                  intensity: 0.7,
                  boxShape: NeumorphicBoxShape.roundRect(
                    BorderRadius.circular(20),
                  ),
                  color: selectedLocale?.languageCode == locale.languageCode
                      ? Colors.orange.shade100
                      : Colors.grey.shade50,
                ),
                padding: const EdgeInsets.all(16),
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
                          fontWeight: selectedLocale?.languageCode == locale.languageCode
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: selectedLocale?.languageCode == locale.languageCode
                              ? Colors.orange.shade800
                              : Colors.black87,
                        ),
                      ),
                    ),
                    if (selectedLocale?.languageCode == locale.languageCode)
                      Neumorphic(
                        style: NeumorphicStyle(
                          depth: -3,
                          boxShape: const NeumorphicBoxShape.circle(),
                          color: Colors.orange.shade600,
                        ),
                        padding: const EdgeInsets.all(4),
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
        ],
      ),
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
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
            ),
            child: SizedBox(
              width: isActive ? 32 : 12,
              height: 12,
            ),
          ),
        );
      }),
    );
  }
}