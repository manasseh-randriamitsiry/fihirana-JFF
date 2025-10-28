import 'package:flutter/material.dart';

class HymnSearchField extends StatelessWidget {
  final TextEditingController controller;
  final TextStyle defaultTextStyle;
  final Color textColor;
  final Color iconColor;
  final VoidCallback onChanged;

  const HymnSearchField({
    super.key,
    required this.controller,
    required this.defaultTextStyle,
    required this.textColor,
    required this.iconColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(
              color: textColor.withOpacity(0.7),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(
              color: textColor.withOpacity(0.7),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(
              color: textColor,
            ),
          ),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
