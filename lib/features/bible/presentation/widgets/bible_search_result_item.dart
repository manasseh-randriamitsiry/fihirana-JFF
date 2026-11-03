import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_search_controller.dart';
import 'package:fihirana/features/bible/domain/entities/bible_search.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/app_typography.dart';

/// A search hit set the way the register sets an entry: the figure in tabular
/// numerals, the words beside it, the whole row a control. The matched phrase
/// takes the accent, and nothing else in the row does.
class BibleSearchResultItem extends StatelessWidget {
  final BibleSearchResult result;

  const BibleSearchResultItem({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = AppSurfaces.of(context);
    final type = Theme.of(context).textTheme;
    final search = Get.find<BibleSearchController>();
    final isVerse = result.type == BibleSearchResultType.verse;

    return Ink(
      decoration: BoxDecoration(
        color: s.paper2,
        borderRadius: BorderRadius.circular(AppScale.radiusRow),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          search.navigateToSearchResult(result);
        },
        borderRadius: BorderRadius.circular(AppScale.radiusRow),
        hoverColor: s.pressed,
        focusColor: s.focus.withValues(alpha: 0.18),
        splashColor: s.accent.withValues(alpha: 0.10),
        highlightColor: s.pressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppScale.space16, vertical: AppScale.space12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppScale.hitTarget),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isVerse) ...[
                  SizedBox(
                    width: AppScale.figureColumn,
                    child: Text('${result.chapter}:${result.verse}',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.figure(s,
                            size: AppScale.figureSm, color: s.ink2)),
                  ),
                  const SizedBox(width: AppScale.space12),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isVerse)
                        _VerseText(result: result, style: type.bodyMedium!)
                      else
                        Text(result.bookName,
                            style: type.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      const SizedBox(height: AppScale.space4),
                      Text(
                        isVerse ? result.bookName : l10n.books,
                        style: type.bodySmall?.copyWith(color: s.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The verse with every occurrence of the word put in the accent colour.
class _VerseText extends StatelessWidget {
  const _VerseText({required this.result, required this.style});

  final BibleSearchResult result;
  final TextStyle style;

  /// A row sets three lines, so a hit late in a long verse would never reach
  /// the screen. The snippet opens just before the word the search found.
  static const int _leadChars = 24;

  static String snippetAround(String text, String query) {
    final index = text.toLowerCase().indexOf(query.toLowerCase());
    if (index <= _leadChars) return text;
    final from = index - _leadChars;
    final space = text.indexOf(' ', from);
    final cut = (space == -1 || space >= index) ? from : space + 1;
    return '… ${text.substring(cut)}';
  }

  @override
  Widget build(BuildContext context) {
    final query = Get.find<BibleSearchController>().searchQuery.value.trim();
    final text =
        query.isEmpty ? result.text : snippetAround(result.text, query);
    if (query.isEmpty) {
      return Text(text,
          style: style, maxLines: 3, overflow: TextOverflow.ellipsis);
    }

    final s = AppSurfaces.of(context);
    final highlight = style.copyWith(
      color: s.accent,
      fontWeight: FontWeight.w700,
      backgroundColor: s.accentSoft,
    );
    final spans = <TextSpan>[];
    final haystack = text.toLowerCase();
    final needle = query.toLowerCase();
    var start = 0;
    var index = haystack.indexOf(needle);
    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(TextSpan(
          text: text.substring(index, index + query.length), style: highlight));
      start = index + query.length;
      index = haystack.indexOf(needle, start);
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
