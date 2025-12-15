import 'package:flutter/material.dart';

import 'package:fihirana/shared/widgets/common/localization_extension.dart';
import 'package:fihirana/shared/widgets/common/app_card.dart';

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
    return AppCard(
      backgroundColor: backgroundColor,
      elevation: 4.0,
      borderRadius: 30.0,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: TextField(
        controller: controller,
        style: defaultTextStyle,
        decoration: InputDecoration(
          labelText: context.translate((l) => l.searchHymnsHint),
          labelStyle: defaultTextStyle.copyWith(
            color: textColor.withValues(alpha: 0.7),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: iconColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: iconColor.withValues(alpha: 0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: iconColor.withValues(alpha: 0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: iconColor.withValues(alpha: 0), width: 2),
          ),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
