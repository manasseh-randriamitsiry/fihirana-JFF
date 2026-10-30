import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/app_typography.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class SongInfoSection extends StatelessWidget {
  final String title;
  final String hymnNumber;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const SongInfoSection({
    super.key,
    required this.title,
    required this.hymnNumber,
    required this.isFavorite,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final AppSurfaces s = AppSurfaces.of(context);
    final TextTheme type = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: type.titleLarge?.copyWith(color: s.ink),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppScale.space4),
              Text(
                hymnNumber,
                style: AppTypography.figure(
                  s,
                  size: AppScale.figureSm,
                  weight: FontWeight.w700,
                  color: s.muted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppScale.space12),
        IconButton(
          tooltip: l10n.favorites,
          onPressed: onToggleFavorite == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onToggleFavorite!();
                },
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: AppScale.iconLg,
            color: isFavorite ? s.accent : s.ink,
          ),
        ),
      ],
    );
  }
}
