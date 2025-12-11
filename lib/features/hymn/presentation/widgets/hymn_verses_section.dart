import 'package:flutter/material.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'hymn_detail_widgets.dart';

class HymnVersesSection extends StatelessWidget {
  final Hymn hymn;
  final double fontSize;
  final double countFontSize;

  const HymnVersesSection({
    super.key,
    required this.hymn,
    required this.fontSize,
    required this.countFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < hymn.verses.length; i++)
          HymnVerseDisplayWidget(
            verseNumber: i + 1,
            verseText: hymn.verses[i],
            fontSize: fontSize,
            countFontSize: countFontSize,
          ),
      ],
    );
  }
}