import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class HymnSearchField extends StatelessWidget {
  final TextEditingController controller;
  final TextStyle defaultTextStyle;
  final Color textColor;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onChanged;

  const HymnSearchField({
    super.key,
    required this.controller,
    required this.defaultTextStyle,
    required this.textColor,
    required this.iconColor,
    required this.backgroundColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: -8,
          intensity: 0.65,
          surfaceIntensity: 0.25,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(30)),
          color: backgroundColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: controller,
          style: defaultTextStyle,
          decoration: InputDecoration(
            labelText: 'Hikaroka hira',
            labelStyle: defaultTextStyle.copyWith(
              color: textColor.withOpacity(0.7),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: iconColor,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onChanged: (_) => onChanged(),
        ),
      ),
    );
  }
}
