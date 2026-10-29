import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/app_typography.dart';
import 'package:fihirana/core/design_system/components/app_sheet.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/bible/domain/entities/note.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'hymn_improved_note_section_widget.dart';

/// The sheet: one printed page, ruled at the head, set in the reader's own
/// voice. Verses are not boxes; they are stanzas with a hanging numeral.
class HymnPageWidget extends StatelessWidget {
  final Hymn hymn;
  final double fontSize;
  final double countFontSize;
  final bool isUserAuthenticated;
  final Note? userNote;
  final Function(Note) onNoteEdit;

  const HymnPageWidget({
    super.key,
    required this.hymn,
    required this.fontSize,
    required this.countFontSize,
    required this.isUserAuthenticated,
    this.userNote,
    required this.onNoteEdit,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final AppSurfaces s = AppSurfaces.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      key: ValueKey(hymn.id),
      color: s.sheet,
      child: CustomScrollView(
        slivers: [
          // 1. Masthead: the number, the title, one firm rule.
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppScale.gutter, AppScale.space24, AppScale.gutter, 0),
            sliver: SliverToBoxAdapter(
              child: HymnMasthead(
                title: hymn.title,
                number: hymn.hymnNumber,
                countFontSize: countFontSize,
                fontSize: fontSize,
              ),
            ),
          ),

          // 2. First verse
          if (hymn.verses.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppScale.gutter, AppScale.space24, AppScale.gutter, 0),
              sliver: SliverToBoxAdapter(
                child: HymnVerse(
                  verseNumber: 1,
                  verseText: hymn.verses[0],
                  fontSize: fontSize,
                ),
              ),
            ),

          // 3. Bridge (sticky)
          if (hymn.bridge != null && hymn.bridge!.trim().isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _BridgeHeaderDelegate(
                label: l10n.chorus,
                bridge: hymn.bridge!,
                labelStyle: type.bodySmall?.copyWith(
                        color: s.muted, fontWeight: FontWeight.w700) ??
                    TextStyle(color: s.muted),
                textStyle: AppTypography.lyricText(
                  context,
                  size: AppTypography.lyricSize(fontSize),
                ).copyWith(fontStyle: FontStyle.italic),
                width: screenWidth,
                textScaler: MediaQuery.of(context).textScaler,
              ),
            ),

          // 4. Remaining verses
          if (hymn.verses.length > 1)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppScale.gutter, AppScale.space24, AppScale.gutter, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: AppScale.space24),
                    child: HymnVerse(
                      verseNumber: index + 2,
                      verseText: hymn.verses[index + 1],
                      fontSize: fontSize,
                    ),
                  ),
                  childCount: hymn.verses.length - 1,
                ),
              ),
            ),

          // 5. Origin and hint
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppScale.gutter, AppScale.space24, AppScale.gutter, 0),
            sliver: SliverToBoxAdapter(
              child: HymnMeta(hymn: hymn),
            ),
          ),

          // 6. User Notes
          if (isUserAuthenticated)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppScale.gutter,
                  AppScale.space24, AppScale.gutter, AppScale.space96),
              sliver: SliverToBoxAdapter(
                child: ImprovedNoteSectionWidget(
                  userNote: userNote,
                  onNoteEdit: onNoteEdit,
                  onAddNote: () => onNoteEdit(userNote ??
                      Note(
                        id: '',
                        hymnId: hymn.id,
                        userId: '',
                        userEmail: '',
                        content: '',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        userName: '',
                      )),
                  fontSize: fontSize,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The head of the page: a numeral the size of a line, the title beside it, the
/// rule that says the words start here.
class HymnMasthead extends StatelessWidget {
  final String title;
  final String number;
  final double fontSize;
  final double countFontSize;

  const HymnMasthead({
    super.key,
    required this.title,
    required this.number,
    required this.fontSize,
    required this.countFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    final double lyric = AppTypography.lyricSize(fontSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              number,
              style: AppTypography.figure(s, size: countFontSize).copyWith(
                fontWeight: FontWeight.w700,
                color: s.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: AppScale.space16),
            Expanded(
              child: Text(
                title,
                style: type.headlineSmall?.copyWith(
                  fontSize: AppTypography.headSize(lyric),
                  color: s.ink,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppScale.space16),
        const AppRule(firm: true),
      ],
    );
  }
}

/// A stanza: the numeral hangs in the figure column, the words run beside it.
class HymnVerse extends StatelessWidget {
  final int verseNumber;
  final String verseText;
  final double fontSize;

  const HymnVerse({
    super.key,
    required this.verseNumber,
    required this.verseText,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppScale.figureColumn,
          child: Text(
            '$verseNumber',
            textAlign: TextAlign.right,
            style: AppTypography.figure(s,
                size: AppScale.figureMd,
                weight: FontWeight.w700,
                color: s.muted),
          ),
        ),
        const SizedBox(width: AppScale.space16),
        Expanded(
          child: Text(
            verseText,
            style: AppTypography.lyricText(context,
                size: AppTypography.lyricSize(fontSize)),
          ),
        ),
      ],
    );
  }
}

/// The facts under the words: who set it down, and what the editors noted.
class HymnMeta extends StatelessWidget {
  final Hymn hymn;

  const HymnMeta({super.key, required this.hymn});

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final bool showCreatedBy = hymn.createdBy.isNotEmpty &&
        hymn.createdBy != 'Local File' &&
        hymn.createdByEmail != null;
    final bool showHint = hymn.hymnHint != null && hymn.hymnHint!.isNotEmpty;

    if (!showCreatedBy && !showHint) {
      return const SizedBox.shrink();
    }

    Widget line(String label, String value, {bool prose = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppScale.space16, vertical: AppScale.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: type.bodySmall
                  ?.copyWith(color: s.muted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppScale.space4),
            Text(
              value,
              style: prose
                  ? type.bodyMedium
                      ?.copyWith(color: s.ink2, fontStyle: FontStyle.italic)
                  : type.bodyMedium?.copyWith(color: s.ink),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: s.paper2,
        borderRadius: BorderRadius.circular(AppScale.radiusSurface),
        border: Border.all(color: s.rule, width: AppScale.ruleHair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showCreatedBy) line(l10n.createdBy(''), hymn.createdBy),
          if (showCreatedBy && showHint) const AppRule(),
          if (showHint) line(l10n.hymnHint, hymn.hymnHint!, prose: true),
        ],
      ),
    );
  }
}

/// The chorus stays under way while the stanzas run past it.
class _BridgeHeaderDelegate extends SliverPersistentHeaderDelegate {
  _BridgeHeaderDelegate({
    required this.label,
    required this.bridge,
    required this.labelStyle,
    required this.textStyle,
    required this.width,
    required this.textScaler,
  });

  final String label;
  final String bridge;
  final TextStyle labelStyle;
  final TextStyle textStyle;
  final double width;
  final TextScaler textScaler;

  static const double _padX = AppScale.gutter;
  static const double _padY = AppScale.space12;
  static const double _gap = AppScale.space8;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final AppSurfaces s = AppSurfaces.of(context);
    return ColoredBox(
      color: s.paper2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppRule(firm: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(_padX, _padY, _padX, _padY),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                const SizedBox(height: _gap),
                Text(bridge, style: textStyle),
              ],
            ),
          ),
          const AppRule(firm: true),
        ],
      ),
    );
  }

  @override
  double get maxExtent => _calculateHeight();

  @override
  double get minExtent => _calculateHeight();

  double _calculateHeight() {
    final double textWidth = math.max(width - 2 * _padX, 1.0);

    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: null,
        textScaler: textScaler,
      )..layout(maxWidth: textWidth);
      return painter.height;
    }

    // The extent uses the styles the band draws, so it never clips a line.
    return measure(bridge, textStyle) +
        measure(label, labelStyle) +
        _gap +
        2 * _padY +
        2 * AppScale.ruleBar;
  }

  @override
  bool shouldRebuild(_BridgeHeaderDelegate oldDelegate) {
    return oldDelegate.bridge != bridge ||
        oldDelegate.label != label ||
        oldDelegate.textStyle != textStyle ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.width != width ||
        oldDelegate.textScaler != textScaler;
  }
}
