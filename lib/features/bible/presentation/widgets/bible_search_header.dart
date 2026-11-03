import 'package:flutter/material.dart';

import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/components/app_sheet.dart';

class BibleSearchHeader extends StatelessWidget {
  const BibleSearchHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = AppSurfaces.of(context);
    final type = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppScale.gutter, AppScale.space12,
              AppScale.space8, AppScale.space8),
          child: Row(
            children: [
              Expanded(
                child: Text(l10n.searchBible,
                    style: type.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                onPressed: () {
                  // Leaving the keyboard up while the route pops tears down the
                  // text input mid-transition.
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.close_rounded,
                    size: AppScale.iconMd, color: s.muted),
                tooltip: l10n.close,
              ),
            ],
          ),
        ),
        const AppRule(),
      ],
    );
  }
}
