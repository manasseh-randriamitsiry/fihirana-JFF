import 'package:flutter/material.dart';

import 'package:fihirana/shared/widgets/common/localization_extension.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

/// The hymn search field. It reads the theme for everything but its hint.
class HymnSearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback? onClear;

  const HymnSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AppSearchField(
      controller: controller,
      hintText: context.translate((l) => l.searchHymnsHint),
      onChanged: (_) => onChanged(),
      onClear: onClear,
    );
  }
}
