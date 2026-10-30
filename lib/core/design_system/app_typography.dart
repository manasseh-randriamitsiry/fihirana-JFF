import 'package:flutter/material.dart';

import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';

/// Type for the register.
///
/// Three families, each with one job: [displayFamily] sets heads and nothing
/// else, the body family the user picked in Settings runs the app, and
/// [figureFamily] sets numerals only. Two weights, 400 and 700; hierarchy comes
/// from size and ink, never from a third weight.
class AppTypography {
  const AppTypography._();

  static const String displayFamily = 'Montserrat';
  static const String figureFamily = 'Hack';
  static const String fallbackBodyFamily = 'Lato';

  // A fixed scale, ratio 1.2 from a 16px body. No fluid heads.
  static const double displayL = 34;
  static const double display = 28;
  static const double headline = 23;
  static const double subhead = 20;
  static const double title = 19;
  static const double bodyL = 17;
  static const double body = 16;
  static const double meta = 13;
  static const double label = 12;

  /// The size a hymn's words are set at, and the only place the app reads long
  /// prose: large enough to carry a verse across a room.
  static const double lyric = 21;
  static const double lyricLead = 1.65;

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static TextTheme textTheme(AppSurfaces s, {String? bodyFamily}) {
    final String ui = bodyFamily ?? fallbackBodyFamily;

    TextStyle role(
      double size, {
      FontWeight weight = FontWeight.w400,
      double height = 1.35,
      Color? color,
      String? family,
      double tracking = 0,
      bool tabular = false,
    }) {
      return TextStyle(
        inherit: false,
        fontFamily: family ?? ui,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: tracking,
        color: color ?? s.ink,
        fontFeatures: tabular ? _tabular : null,
        // Material widgets such as ListTile assert on this; a style built with
        // inherit: false has none of the platform defaults left to fall back on.
        textBaseline: TextBaseline.alphabetic,
        leadingDistribution: TextLeadingDistribution.even,
      );
    }

    TextStyle head(double size, {double height = 1.1}) => role(
          size,
          weight: FontWeight.w700,
          height: height,
          family: displayFamily,
          tracking: size * -0.02,
          color: s.ink,
        );

    return TextTheme(
      displayLarge: head(displayL, height: 1.02),
      displayMedium: head(display, height: 1.05),
      displaySmall: head(headline),
      headlineLarge: head(display),
      headlineMedium: head(headline),
      headlineSmall: head(subhead),
      titleLarge: head(title),
      titleMedium: role(body, weight: FontWeight.w700, color: s.ink),
      titleSmall: role(body, color: s.ink2),
      bodyLarge: role(bodyL, height: 1.5, color: s.ink),
      bodyMedium: role(body, height: 1.5, color: s.ink),
      bodySmall: role(meta, height: 1.4, color: s.muted),
      labelLarge: role(14, weight: FontWeight.w700, height: 1, color: s.ink),
      labelMedium: role(meta, height: 1.2, color: s.muted),
      labelSmall: role(label, height: 1.2, color: s.muted),
    );
  }

  /// A numeral that compares with its neighbours: a hymn number, a time, a
  /// count. Right-aligned, tabular, in the figure family.
  static TextStyle figure(AppSurfaces s,
      {double size = AppScale.figureMd,
      FontWeight weight = FontWeight.w400,
      Color? color}) {
    return TextStyle(
      inherit: false,
      fontFamily: figureFamily,
      fontSize: size,
      fontWeight: weight,
      height: 1.2,
      color: color ?? s.ink,
      fontFeatures: _tabular,
      textBaseline: TextBaseline.alphabetic,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  /// A head leads the prose it heads by one step of the 1.2 ratio.
  static double headSize(double proseSize) => proseSize * 1.2;

  /// The words of a hymn, set at the size a room reads.
  ///
  /// It takes the body family from the active theme, so the face the user picked
  /// in Settings runs the reader; [size] is the theme's lyric size unless the
  /// reader scales it with the font-size preference.
  static TextStyle lyricText(BuildContext context, {double? size}) {
    final TextStyle base =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return base.copyWith(
      fontSize: size ?? lyric,
      height: lyricLead,
      fontWeight: FontWeight.w400,
      fontStyle: null,
      color: AppSurfaces.of(context).ink,
    );
  }

  /// The reader sets its words larger than the UI, and the font-size preference
  /// scales around that offset.
  static double lyricSize(double uiFontSize) => uiFontSize * lyric / body;
}
