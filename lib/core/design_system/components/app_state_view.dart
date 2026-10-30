import 'package:flutter/material.dart';

import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';

/// The four states every region that loads data has to answer.
enum AppState { loading, empty, error, full }

/// Wraps a data region and draws the state it is in.
class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.state,
    required this.child,
    required this.emptyTitle,
    this.emptyMessage,
    this.emptyAction,
    this.errorTitle,
    this.errorMessage,
    this.onRetry,
    this.skeletonRows = 8,
    this.emptyIcon,
  });

  final AppState state;
  final Widget child;
  final String emptyTitle;
  final String? emptyMessage;
  final Widget? emptyAction;
  final String? errorTitle;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final int skeletonRows;
  final IconData? emptyIcon;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case AppState.loading:
        return AppRegisterSkeleton(rows: skeletonRows);
      case AppState.empty:
        return AppNotice(
          title: emptyTitle,
          message: emptyMessage,
          action: emptyAction,
          icon: emptyIcon,
        );
      case AppState.error:
        return AppNotice(
          title: errorTitle ??
              context.translate((l) => l.error),
          message: errorMessage,
          action: onRetry == null
              ? null
              : FilledButton.tonal(
                  onPressed: onRetry,
                  child: Text(context.translate((l) => l.tryAgain))),
          alarm: true,
        );
      case AppState.full:
        return child;
    }
  }
}

/// What an empty or a broken region says: the fact, why it matters, one action.
class AppNotice extends StatelessWidget {
  const AppNotice({
    super.key,
    required this.title,
    this.message,
    this.action,
    this.alarm = false,
    this.icon,
  });

  final String title;
  final String? message;
  final Widget? action;
  final bool alarm;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppScale.space40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppScale.iconLg, color: s.muted),
              const SizedBox(height: AppScale.space12),
            ],
            Container(width: 32, height: AppScale.ruleBar, color: s.ruleFirm),
            const SizedBox(height: AppScale.space16),
            Text(title, style: type.headlineSmall, textAlign: TextAlign.left),
            if (message != null) ...[
              const SizedBox(height: AppScale.space8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  message!,
                  style: type.bodyMedium?.copyWith(
                      color: alarm
                          ? Theme.of(context).colorScheme.error
                          : s.muted),
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppScale.space24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// The shape of the register, before the register arrives.
class AppRegisterSkeleton extends StatelessWidget {
  const AppRegisterSkeleton({super.key, this.rows = 8});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows,
      separatorBuilder: (_, __) => const SizedBox(height: AppScale.space8),
      itemBuilder: (context, i) => Container(
        height: AppScale.listItemMin,
        decoration: BoxDecoration(
          color: s.paper2,
          borderRadius: BorderRadius.circular(AppScale.radiusRow),
          border: Border.all(color: s.rule, width: AppScale.ruleHair),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppScale.space16, vertical: AppScale.space12),
          child: Row(
            children: [
              _Bar(width: AppScale.figureColumn, color: s.paper3, align: TextAlign.right),
              const SizedBox(width: AppScale.space16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bar(width: 180, color: s.paper3),
                    const SizedBox(height: AppScale.space8),
                    _Bar(width: 96, color: s.paper3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.color, this.align});

  final double width;
  final Color color;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: align == TextAlign.right
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        width: width,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppScale.radiusMark),
        ),
      ),
    );
  }
}
