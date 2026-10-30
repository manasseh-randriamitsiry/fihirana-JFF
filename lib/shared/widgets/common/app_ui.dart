import 'package:flutter/material.dart';

import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/app_typography.dart';
import 'package:fihirana/core/design_system/components/app_register_row.dart';
import 'package:fihirana/core/design_system/components/app_sheet.dart';
import 'package:fihirana/core/design_system/components/app_state_view.dart';

/// Shared building blocks for the app's screens, all of them read from the
/// design system: a screen passes content and labels, never colours or lengths.
class AppPageScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? leading;
  final List<Widget> actions;
  final bool largeTitle;
  final Widget? bottomBar;

  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.leading,
    this.actions = const [],
    this.largeTitle = false,
    this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme type = Theme.of(context).textTheme;
    final AppSurfaces s = AppSurfaces.of(context);
    return Scaffold(
      backgroundColor: s.paper,
      appBar: AppBar(
        leading: leading,
        title: Text(
          title,
          style: largeTitle ? type.displaySmall : type.titleLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: actions,
      ),
      body: SafeArea(top: false, child: body),
      bottomNavigationBar: bottomBar,
    );
  }
}

/// A titled group of content: the label, a firm rule, then what it heads.
class AppSection extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppSection({
    super.key,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
        AppScale.gutter, AppScale.space24, AppScale.gutter, 0),
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme type = Theme.of(context).textTheme;
    final AppSurfaces s = AppSurfaces.of(context);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: type.labelLarge
                ?.copyWith(color: s.muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppScale.space12),
          child,
        ],
      ),
    );
  }
}

/// A set of rows that belong together: a rounded, ruled sheet of paper.
class AppGroupedSurface extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const AppGroupedSurface({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    return Container(
      decoration: BoxDecoration(
        color: s.sheet,
        borderRadius: BorderRadius.circular(AppScale.radiusSurface),
      ),
      // Flush rows splash square; the group clips them to its own corner.
      clipBehavior: Clip.antiAlias,
      padding: padding,
      // The group is the card, so the rows inside it stay flush.
      child: GroupedRows(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// One tappable card.
///
/// A card that holds a single action is not a group of rows: it carries its own
/// paper, rule and corner, and the ripple fills that same box. Nothing inside it
/// gets a second surface.
class AppTapCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const AppTapCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppScale.space16),
  });

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    final BorderRadius corner = BorderRadius.circular(AppScale.radiusRow);
    final bool enabled = onTap != null;
    return Ink(
      decoration: BoxDecoration(
        color: s.paper2,
        borderRadius: corner,
      ),
      child: Semantics(
        button: enabled,
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: corner),
          hoverColor: s.pressed,
          focusColor: s.focus.withValues(alpha: 0.18),
          splashColor: s.accent.withValues(alpha: 0.10),
          highlightColor: s.pressed,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class AppGroupDivider extends StatelessWidget {
  const AppGroupDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppRule(indent: AppScale.gutter + AppScale.iconLg + 14);
  }
}

class AppListRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool destructive;

  const AppListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    return AppRegisterRow(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      destructive: destructive,
      leadingWidget: Builder(builder: (context) {
        final Color ink = destructive
            ? Theme.of(context).colorScheme.error
            : (iconColor ?? s.ink);
        return Icon(icon, color: ink, size: AppScale.iconLg);
      }),
    );
  }
}

/// The search field. Its trailing slot is always reserved, so a clear button
/// arriving never moves the field.
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded, size: AppScale.iconLg),
        suffixIcon: IconButton(
          onPressed: onClear,
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close_rounded, size: AppScale.iconLg),
        ),
      ),
    );
  }
}

/// What an empty region says: the fact, why it matters, one action.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return AppStateView(
      state: AppState.empty,
      emptyTitle: title,
      emptyMessage: message,
      emptyAction: action,
      emptyIcon: icon,
      child: const SizedBox.shrink(),
    );
  }
}

/// A numeral that belongs to a row: a hymn number, a count, a duration.
class AppFigure extends StatelessWidget {
  final String value;
  final double size;
  final TextAlign align;

  const AppFigure(
    this.value, {
    super.key,
    this.size = AppScale.figureMd,
    this.align = TextAlign.right,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.figure(AppSurfaces.of(context), size: size),
    );
  }
}
