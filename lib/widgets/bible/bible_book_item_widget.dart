import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../controller/bible_controller.dart';

class BibleBookItemWidget extends StatelessWidget {
  final String bookName;
  final VoidCallback onTap;

  const BibleBookItemWidget({
    super.key,
    required this.bookName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final bibleController = Get.find<BibleController>();
    final chapterCount = bibleController.getChapterCountForBook(bookName);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorController.primaryColor.value.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          bookName,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: colorController.textColor.value,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colorController.primaryColor.value.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$chapterCount',
            style: TextStyle(
              color: colorController.primaryColor.value,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}