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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      key: ValueKey(hymn.id),
      color: colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          // 1. Header (Title & Number)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: HymnHeaderCard(
                title: hymn.title,
                number: hymn.hymnNumber,
                fontSize: fontSize,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 2. First Verse
          if (hymn.verses.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: HymnVerseCard(
                  verseNumber: 1,
                  verseText: hymn.verses[0],
                  fontSize: fontSize,
                ),
              ),
            ),

          if (hymn.verses.isNotEmpty) const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 3. Bridge (Sticky)
          if (hymn.bridge != null && hymn.bridge!.trim().isNotEmpty) ...[
            SliverPersistentHeader(
              pinned: true,
              delegate: _BridgeHeaderDelegate(
                bridge: hymn.bridge!,
                fontSize: fontSize,
                colorScheme: colorScheme,
                textTheme: theme.textTheme,
                maxWidth: screenWidth - 32, // Horizontal padding of screen (16*2)
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],

          // 4. Remaining Verses
          if (hymn.verses.length > 1)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Start from the second verse (index 1)
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
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


          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 4. Notes / Info
          SliverPadding(
             padding: const EdgeInsets.symmetric(horizontal: 16),
             sliver: SliverToBoxAdapter(
                child: HymnInfoCard(
                  hymn: hymn,
                  fontSize: fontSize,
                ),
             ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 5. User Notes
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverToBoxAdapter(
              child: ImprovedNoteSectionWidget(
                isUserAuthenticated: isUserAuthenticated,
                publicNotes: publicNotes,
                userNote: userNote,
                onNoteEdit: onNoteEdit,
                onAddNote: () => onNoteEdit(userNote ?? Note(
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
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final double maxWidth;

  _BridgeHeaderDelegate({
    required this.bridge,
    required this.fontSize,
    required this.colorScheme,
    required this.textTheme,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // The bridge content
    return Container(
       // Add background color to handle overlap transparency
       color: colorScheme.surface, 
       padding: const EdgeInsets.symmetric(horizontal: 16),
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
    
    final textStyle = textTheme.bodyLarge?.copyWith(
      fontSize: fontSize,
      fontStyle: FontStyle.italic,
      height: 1.6,
    ) ?? TextStyle(fontSize: fontSize, height: 1.6);

    final textSpan = TextSpan(text: bridge, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: null,
    );
    
    final cardContentWidth = maxWidth - 40; // 40 is Card internal padding (20*2)

    textPainter.layout(maxWidth: cardContentWidth);
    
    // Height = TextHeight + TitleHeight(approx 24) + Spacing(12) + CardPadding(40).
    return textPainter.height + 24 + 12 + 40 + 10; // +10 buffer
  }

  @override
  bool shouldRebuild(_BridgeHeaderDelegate oldDelegate) {
    return oldDelegate.bridge != bridge || oldDelegate.fontSize != fontSize;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
          bottom: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      color: colorScheme.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.repeat_rounded, size: 20, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  l10n.chorus, // Bridge/Chorus
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              bridge,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: fontSize,
                fontStyle: FontStyle.italic,
                height: 1.6,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.verseWithNumber(verseNumber), // Verse N
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              verseText,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: fontSize,
                height: 1.8, // Relaxed line height for readability
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final bool showCreatedBy = hymn.createdBy.isNotEmpty &&
        hymn.createdBy != 'Local File' &&
        hymn.createdByEmail != null;
    
    final bool showHint = hymn.hymnHint != null && hymn.hymnHint!.isNotEmpty;

    // If no info, show nothing
    if (!showCreatedBy && !showHint) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (showCreatedBy) ...[
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 20, color: colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Text(
                     l10n.createdBy(''),
                     style: theme.textTheme.labelMedium?.copyWith(
                       color: colorScheme.tertiary,
                       fontWeight: FontWeight.bold,
                     ),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: Text(
                      hymn.createdBy,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onTertiaryContainer,
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
                  Icon(Icons.info_outline_rounded, size: 20, color: colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hymn.hymnHint!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}