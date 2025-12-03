import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';

class HymnSeparator extends StatelessWidget {
  const HymnSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return Column(
      children: [
        const SizedBox(height: 30),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          height: 1,
          color: colorController.textColor.value.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}