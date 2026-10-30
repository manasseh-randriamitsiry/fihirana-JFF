import 'package:flutter/material.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class PlayerTopBar extends StatelessWidget {
  final VoidCallback? onClose;

  const PlayerTopBar({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final AppSurfaces s = AppSurfaces.of(context);
    final TextTheme type = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppScale.gutter, vertical: AppScale.space8),
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                size: AppScale.iconLg),
            onPressed: onClose ?? () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              l10n.nowPlaying,
              style: type.bodySmall
                  ?.copyWith(color: s.muted, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
