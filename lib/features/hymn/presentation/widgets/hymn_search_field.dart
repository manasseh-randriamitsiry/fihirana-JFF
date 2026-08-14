import 'package:flutter/material.dart';

import 'package:fihirana/shared/widgets/common/localization_extension.dart';

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
    return TextField(
      controller: controller,
      style: defaultTextStyle,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.translate((l) => l.searchHymnsHint),
        prefixIcon: Icon(Icons.search_rounded, color: iconColor),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}
