import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/bible/domain/entities/bible_search.dart';

class BibleSearchResultItem extends StatelessWidget {
  final BibleSearchResult result;
  final double fontSize;

  const BibleSearchResultItem({
    super.key,
    required this.result,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final bibleController = Get.find<BibleController>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorController.primaryColor.value.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorController.primaryColor.value.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          bibleController.navigateToSearchResult(result);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    result.type == BibleSearchResultType.book
                        ? Icons.book_rounded
                        : Icons.article_rounded,
                    color: colorController.primaryColor.value,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.displayText,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: colorController.primaryColor.value,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (result.type == BibleSearchResultType.verse)
                _buildHighlightedVerseText(bibleController, colorController)
              else
                Text(
                  result.subtitle,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color:
                        colorController.textColor.value.withValues(alpha: 0.7),
                    fontSize: fontSize * 0.9,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedVerseText(BibleController bibleController, ColorController colorController) {
    final query = bibleController.searchQuery.value;
    if (query.isEmpty) {
      return Text(
        result.text,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: colorController.textColor.value.withValues(alpha: 0.7),
          fontSize: fontSize * 0.9,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    final List<TextSpan> spans = [];
    final lowerText = result.text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: result.text.substring(start, index),
          style: TextStyle(
            fontFamily: 'Roboto',
            color: colorController.textColor.value.withValues(alpha: 0.7),
            fontSize: fontSize * 0.9,
          ),
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: result.text.substring(index, index + query.length),
        style: TextStyle(
          fontFamily: 'Roboto',
          backgroundColor:
              colorController.primaryColor.value.withValues(alpha: 0.3),
          color: colorController.primaryColor.value,
          fontSize: fontSize * 0.9,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // Add remaining text
    if (start < result.text.length) {
      spans.add(TextSpan(
        text: result.text.substring(start),
        style: TextStyle(
          fontFamily: 'Roboto',
          color: colorController.textColor.value.withValues(alpha: 0.7),
          fontSize: fontSize * 0.9,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}