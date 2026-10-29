import 'package:flutter/animation.dart';

/// The fixed measure of the design system. Every length, duration and radius in
/// the app is read from here; a raw number in a widget is a defect.
///
/// Surfaces are ruled and rounded: depth comes from a hairline, a firm rule and
/// a paper step, never from a shadow. The rules themselves stay square; only
/// the surfaces they enclose carry a corner.
class AppScale {
  const AppScale._();

  // Spacing: a 4-based ladder, the only gaps a widget may take.
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space40 = 40;
  static const double space64 = 64;
  static const double space96 = 96;

  // Rules: two weights carry every surface.
  static const double ruleHair = 1;
  static const double ruleBar = 2;

  // Radii: one corner per nesting level, smallest sits inside the largest.
  // A control rounds first, the surface that collects controls rounds wider,
  // and a sheet that lifts off the edge is wider still.
  static const double radiusControl = 10;
  static const double radiusRow = 12;
  static const double radiusSurface = 16;
  static const double radiusSheet = 20;

  // A checkbox is too small for the control radius; it would read as a circle.
  static const double radiusMark = 5;

  // Floating touch chrome: a mini player or a grab tab that lifts off the edge
  // behaves like phone chrome, not like the printed sheet underneath it.
  static const double radiusFloat = 22;

  // A pill is not a corner at all: it is the two ends of a capsule.
  static const double radiusPill = 999;
  static const double floatInset = 12;
  static const double blurFloat = 24;
  static const double offsetFloat = 6;

  // Controls: 40 on the body of a screen, 44 where a finger aims.
  static const double controlDense = 32;
  static const double control = 40;
  static const double hitTarget = 44;
  static const double button = 48;
  static const double field = 44;

  // Two controls that a finger can hit must never touch: this is the narrowest
  // gap allowed between adjacent buttons, chips or icon targets.
  static const double buttonGap = 12;
  static const double listItemMin = 56;
  static const double rowHeight = 52;
  static const double navBarHeight = 64;
  static const double appBarHeight = 56;
  static const double drawerWidth = 300;

  // The register's number column: wide enough for the longest hymn number.
  static const double figureColumn = 44;
  static const double gutter = 20;

  // Motion: state only, never decoration.
  static const Duration durMicro = Duration(milliseconds: 120);
  static const Duration durShort = Duration(milliseconds: 220);
  static const Duration durLong = Duration(milliseconds: 420);
  static const Curve easeOut = Cubic(0.16, 1, 0.3, 1);
  static const Curve easeIn = Cubic(0.7, 0, 0.84, 0);
  static const Curve easeInOut = Cubic(0.65, 0, 0.35, 1);

  // Numerals that compare are tabular; these are the only mono sizes.
  static const double figureSm = 13;
  static const double figureMd = 16;
  static const double figureLg = 20;

  // Icons: one family, three sizes, and the same optical weight throughout.
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconSlot = 24;

  // The leading block of a card row, and the masthead mark of a page: one
  // square, big enough to read as an object rather than as a glyph.
  static const double tile = 48;
}
