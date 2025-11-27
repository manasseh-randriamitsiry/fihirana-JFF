import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';


class BibleChapterGridWidget extends StatelessWidget {
  final List<int> chapters;
  final Function(int) onChapterSelected;

  const BibleChapterGridWidget({
    super.key,
    required this.chapters,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return InkWell(
          onTap: () => onChapterSelected(chapter),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: colorController.primaryColor.value.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorController.primaryColor.value.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Text(
                '$chapter',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: colorController.primaryColor.value,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}