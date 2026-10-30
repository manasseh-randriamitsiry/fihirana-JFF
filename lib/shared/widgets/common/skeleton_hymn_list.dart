import 'package:flutter/material.dart';

import 'package:fihirana/core/design_system/components/app_state_view.dart';

/// The register's loading state, kept as a named widget so every hymn list can
/// ask for the same shape. It does not shimmer: nothing moves except state.
class SkeletonHymnList extends StatelessWidget {
  const SkeletonHymnList({super.key, this.rows = 8});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return AppRegisterSkeleton(rows: rows);
  }
}
