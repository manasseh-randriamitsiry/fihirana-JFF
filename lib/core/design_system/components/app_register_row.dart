import 'package:flutter/material.dart';

import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/app_typography.dart';

/// The signal a row reads when it is collected inside a grouped surface.
///
/// A group owns its own paper, corner and rule, so a row inside it must not
/// draw a second card around itself; it stays flush and lets the group's
/// divider part it from its neighbours.
class GroupedRows extends InheritedWidget {
  const GroupedRows({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GroupedRows>() != null;

  @override
  bool updateShouldNotify(GroupedRows oldWidget) => false;
}

/// The register row: the one object this app is known by.
///
/// A numbered entry set the way a printed concordance sets it — the figure
/// flush right in tabular numerals, the name beside it. The row is a control,
/// not a line of text: it carries a paper step, a hairline and a corner, and
/// the list that holds it gives it air on every side. The row the page points
/// at takes the accent, a fill and a bar at its edge; nothing else does.
class AppRegisterRow extends StatelessWidget {
  static const BorderRadius _corner =
      BorderRadius.all(Radius.circular(AppScale.radiusRow));
  static const ShapeBorder _ink = RoundedRectangleBorder(borderRadius: _corner);

  const AppRegisterRow({
    super.key,
    required this.title,
    this.figure,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.destructive = false,
    this.leadingWidget,
    this.dense = false,
  });

  /// The hymn number, chapter and verse, or duration. Numerals only.
  final String? figure;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool destructive;
  final Widget? leadingWidget;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    final bool enabled = onTap != null || onLongPress != null;
    // Inside a grouped surface the group is the card; on its own the row is.
    final bool grouped = GroupedRows.of(context);
    final Color titleInk = !enabled
        ? s.muted
        : destructive
            ? Theme.of(context).colorScheme.error
            : selected
                ? s.accent
                : s.ink;

    return Ink(
      decoration: BoxDecoration(
        color: selected
            ? s.accentSoft
            : (grouped ? Colors.transparent : s.paper2),
        borderRadius:
            grouped ? null : BorderRadius.circular(AppScale.radiusRow),
        border: grouped
            ? null
            : Border.all(
                color: selected ? s.accent : s.rule,
                width: AppScale.ruleHair,
              ),
      ),
      child: Semantics(
        button: enabled,
        selected: selected,
        enabled: enabled,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          hoverColor: s.pressed,
          focusColor: s.focus.withValues(alpha: 0.18),
          splashColor: s.accent.withValues(alpha: 0.10),
          highlightColor: s.pressed,
          // The ink has to follow the corner, or a tapped row shows a square.
          customBorder: grouped ? null : _ink,
          // The row sits in a vertical list, where its height is unbounded: the
          // selected bar is a Stack child measured against the row's own height,
          // never a stretched Row.
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: dense ? AppScale.hitTarget : AppScale.listItemMin,
            ),
            // A single-line row is shorter than the row's minimum height, and a
            // Stack aligns its children to the top by default: without this the
            // label of a one-line entry sits high in its own card.
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (selected)
                  Positioned(
                    left: grouped ? 0 : AppScale.space4,
                    top: AppScale.space12,
                    bottom: AppScale.space12,
                    child: SizedBox(
                      width: AppScale.ruleBar,
                      child: ColoredBox(color: s.accent),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: grouped
                          ? AppScale.gutter
                          : AppScale.space16,
                      vertical: AppScale.space12),
                  child: Row(
                    children: [
                      if (figure != null)
                        SizedBox(
                          width: AppScale.figureColumn,
                          child: Text(
                            figure!,
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: AppTypography.figure(
                              s,
                              size: AppScale.figureMd,
                              weight:
                                  selected ? FontWeight.w700 : FontWeight.w400,
                            ).copyWith(color: titleInk),
                          ),
                        )
                      else if (leadingWidget != null)
                        leadingWidget!
                      else
                        const SizedBox(width: 0),
                      SizedBox(
                          width: (figure != null || leadingWidget != null)
                              ? 14
                              : 0),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: (dense ? type.bodyMedium : type.bodyLarge)
                                  ?.copyWith(
                                color: titleInk,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: type.bodySmall?.copyWith(
                                    // A row with no action is still read, so its
                                    // second line keeps a legible grey.
                                    color: enabled
                                        ? s.muted
                                        : s.muted.withValues(alpha: 0.7)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      trailing ??
                          (enabled
                              ? Icon(Icons.chevron_right_rounded,
                                  color: s.muted, size: AppScale.iconLg)
                              : const SizedBox.shrink()),
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
