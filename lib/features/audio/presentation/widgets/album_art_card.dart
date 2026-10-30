import 'package:flutter/material.dart';

import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/app_typography.dart';

/// The player has no artwork, so it shows the thing the app does have: the
/// hymn's number, set as large as the space allows on a ruled, rounded plate.
class HymnPlate extends StatelessWidget {
  final String hymnNumber;

  const HymnPlate({
    super.key,
    required this.hymnNumber,
  });

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.sheet,
        borderRadius: BorderRadius.circular(AppScale.radiusSurface),
        border: Border.all(color: s.ruleFirm, width: AppScale.ruleHair),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppScale.space40),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            hymnNumber,
            maxLines: 1,
            softWrap: false,
            style: AppTypography.figure(s,
                size: AppTypography.displayL, weight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
