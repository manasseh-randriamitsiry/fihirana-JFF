import 'package:flutter/material.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/bible/domain/entities/note.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'hymn_improved_note_section_widget.dart';

class HymnPageWidget extends StatelessWidget {
  final Hymn hymn;
  final double fontSize;
  final double countFontSize;
  final bool showHint;
  final bool isUserAuthenticated;
  final List<Note> publicNotes;
  final Note? userNote;
  final Function(Note) onNoteEdit;

  const HymnPageWidget({
    super.key,
    required this.hymn,
    required this.fontSize,
    required this.countFontSize,
    required this.showHint,
    required this.isUserAuthenticated,
    required this.publicNotes,
    this.userNote,
    required this.onNoteEdit,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: ValueKey(hymn.id),
      color: colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          // 1. Header (Title & Number)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: HymnHeaderCard(
                title: hymn.title,
                number: hymn.hymnNumber,
                fontSize: fontSize,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 2. First Verse
          if (hymn.verses.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: HymnVerseCard(
                  verseNumber: 1,
                  verseText: hymn.verses[0],
                  fontSize: fontSize,
                ),
              ),
            ),

          if (hymn.verses.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 3. Bridge (Sticky)
          if (hymn.bridge != null && hymn.bridge!.trim().isNotEmpty) ...[
            SliverPersistentHeader(
              pinned: true,
              delegate: _BridgeHeaderDelegate(
                bridge: hymn.bridge!,
                fontSize: fontSize,
                maxWidth: screenWidth - 40,
                textScaler: MediaQuery.of(context).textScaler,
                defaultTextStyle: DefaultTextStyle.of(context).style,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],

          // 4. Remaining Verses
          if (hymn.verses.length > 1)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Start from the second verse (index 1)
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: HymnVerseCard(
                        verseNumber: index + 2,
                        verseText: hymn.verses[index + 1],
                        fontSize: fontSize,
                      ),
                    );
                  },
                  childCount: hymn.verses.length - 1,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 4. Notes / Info
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: HymnInfoCard(
                hymn: hymn,
                fontSize: fontSize,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 5. User Notes
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverToBoxAdapter(
              child: ImprovedNoteSectionWidget(
                isUserAuthenticated: isUserAuthenticated,
                publicNotes: publicNotes,
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

class _BridgeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String bridge;
  final double fontSize;
  final double maxWidth;
  final TextScaler textScaler;
  final TextStyle defaultTextStyle;

  _BridgeHeaderDelegate({
    required this.bridge,
    required this.fontSize,
    required this.maxWidth,
    required this.textScaler,
    required this.defaultTextStyle,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.center,
      child: HymnBridgeCard(
        bridge: bridge,
        fontSize: fontSize,
      ),
    );
  }

  @override
  double get maxExtent => _calculateHeight();

  @override
  double get minExtent => _calculateHeight();

  double _calculateHeight() {
    // Calculate estimated height of the Bridge Card
    // Card Padding: 20 vertical (20 top + 20 bottom)
    // Row (Icon + Title): 24 roughly + 12 vertical gap
    // Text: Calculated

    final calculatedStyle = TextStyle(
      fontSize: fontSize,
      fontStyle: FontStyle.italic,
      height: 1.6,
    );

    // Merge with default global style to pick up fonts etc, but let our style override.
    final mergedStyle = defaultTextStyle.merge(calculatedStyle);

    final textSpan = TextSpan(text: bridge, style: mergedStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: null,
      textScaler: textScaler,
    );

    final cardContentWidth =
        maxWidth - 40; // 40 is Card internal padding (20*2)

    textPainter.layout(maxWidth: cardContentWidth);

    // Height = text + label row + spacing + vertical card and header padding.
    return textPainter.height + 80;
  }

  @override
  bool shouldRebuild(_BridgeHeaderDelegate oldDelegate) {
    return oldDelegate.bridge != bridge ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.textScaler != textScaler;
  }
}

class HymnHeaderCard extends StatelessWidget {
  final String title;
  final String number;
  final double fontSize;

  const HymnHeaderCard({
    super.key,
    required this.title,
    required this.number,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: .65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  number,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontSize: fontSize * 1.5,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class HymnBridgeCard extends StatelessWidget {
  final String bridge;
  final double fontSize;

  const HymnBridgeCard({
    super.key,
    required this.bridge,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: .65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.repeat_rounded,
                  size: 18,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.chorus,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bridge,
            style: TextStyle(
              fontSize: fontSize,
              fontStyle: FontStyle.italic,
              height: 1.6,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class HymnVerseCard extends StatelessWidget {
  final int verseNumber;
  final String verseText;
  final double fontSize;

  const HymnVerseCard({
    super.key,
    required this.verseNumber,
    required this.verseText,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: .65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.verseWithNumber(verseNumber),
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            verseText,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.8,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class HymnInfoCard extends StatelessWidget {
  final Hymn hymn;
  final double fontSize;

  const HymnInfoCard({
    super.key,
    required this.hymn,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final bool showCreatedBy = hymn.createdBy.isNotEmpty &&
        hymn.createdBy != 'Local File' &&
        hymn.createdByEmail != null;

    final bool showHint = hymn.hymnHint != null && hymn.hymnHint!.isNotEmpty;

    // If no info, show nothing
    if (!showCreatedBy && !showHint) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: .65),
        ),
      ),
      child: Column(
        children: [
          if (showCreatedBy) ...[
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.createdBy(''),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Expanded(
                  flex: 2,
                  child: Text(
                    hymn.createdBy,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (showHint) const SizedBox(height: 12),
          ],
          if (showHint)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hymn.hymnHint!,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
