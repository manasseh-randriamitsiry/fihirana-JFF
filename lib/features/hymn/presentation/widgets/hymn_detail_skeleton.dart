import 'package:flutter/material.dart';

import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/components/app_sheet.dart';

/// The sheet's loading state: the shape of a masthead and three stanzas, drawn
/// in paper steps. Nothing moves, because a page that has not arrived has
/// nothing to shimmer over.
class HymnDetailSkeleton extends StatelessWidget {
  const HymnDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppScale.gutter, AppScale.space24, AppScale.gutter, AppScale.space96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Bar(width: 64, height: 30, color: s.paper3),
              const SizedBox(width: AppScale.space16),
              Expanded(child: _Bar(frac: .8, height: 22, color: s.paper3)),
            ],
          ),
          const SizedBox(height: AppScale.space16),
          const AppRule(firm: true),
          for (int stanza = 0; stanza < 3; stanza++) ...[
            const SizedBox(height: AppScale.space24),
            _Stanza(number: s.paper3, lines: s.paper2),
          ],
        ],
      ),
    );
  }
}

class _Stanza extends StatelessWidget {
  const _Stanza({required this.number, required this.lines});

  final Color number;
  final Color lines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppScale.figureColumn,
          child: Align(
              alignment: Alignment.topRight,
              child: _Bar(frac: 1, height: AppScale.figureMd, color: number)),
        ),
        const SizedBox(width: AppScale.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int line = 0; line < 4; line++) ...[
                _Bar(
                    frac: line == 3 ? .55 : .94 - (line % 3) * .08,
                    height: AppScale.space12,
                    color: lines),
                if (line != 3) const SizedBox(height: AppScale.space8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A line of type that has not arrived yet: a paper step in the shape of a word.
class _Bar extends StatelessWidget {
  const _Bar({
    this.width,
    this.frac = 1,
    required this.height,
    required this.color,
  });

  final double? width;
  final double frac;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (width != null) {
      return SizedBox(width: width, height: height);
    }
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: constraints.maxWidth * frac,
        height: height,
        child: ColoredBox(color: color),
      ),
    );
  }
}
