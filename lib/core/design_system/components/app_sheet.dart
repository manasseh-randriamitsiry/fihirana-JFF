import 'package:flutter/material.dart';

import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/app_typography.dart';

/// The surface ladder: air, a hairline, a paper step, a sheet. Nothing casts a
/// shadow, so depth comes from a rule and from how wide a corner is turned.

/// A rule that means something: a hairline parts rows, a bar closes a head.
/// Rules are the one thing in the system that stays square.
class AppRule extends StatelessWidget {
  const AppRule({super.key, this.firm = false, this.indent = 0});

  final bool firm;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    return Container(
      height: firm ? AppScale.ruleBar : AppScale.ruleHair,
      margin: EdgeInsets.only(left: indent),
      color: firm ? s.ruleFirm : s.rule,
    );
  }
}

/// A band of the next paper step down: a well, an inset, an alternate row.
class AppWell extends StatelessWidget {
  const AppWell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
        horizontal: AppScale.space16, vertical: AppScale.space12),
    this.deep = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool deep;

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    return Container(
      decoration: BoxDecoration(
        color: deep ? s.paper3 : s.paper2,
        borderRadius: BorderRadius.circular(AppScale.radiusRow),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// The printed page: a pale stock laid on the paper with a firm rule at its
/// head. This is where the words of a hymn sit.
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.child,
    this.head,
    this.trailing,
    this.padding = const EdgeInsets.all(AppScale.space16),
  });

  final Widget child;
  final String? head;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: s.sheet,
        borderRadius: BorderRadius.circular(AppScale.radiusSurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (head != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppScale.space16,
                  AppScale.space12, AppScale.space12, AppScale.space8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(head!,
                        style: type.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            const AppRule(),
          ],
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// A group head for a register or a settings list: the body face, a step
/// smaller, sentence case, untracked, with a bar under it.
class AppGroupHead extends StatelessWidget {
  const AppGroupHead({super.key, required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppScale.gutter, AppScale.space24, AppScale.gutter, AppScale.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                  child: Text(title,
                      style: type.labelLarge?.copyWith(
                          color: s.muted, fontWeight: FontWeight.w600))),
              if (count != null)
                Text('$count',
                    style: AppTypography.figure(s, size: AppScale.figureSm)),
            ],
          ),
        ],
      ),
    );
  }
}
