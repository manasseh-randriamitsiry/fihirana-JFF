import 'package:flutter/material.dart';

import 'package:fihirana/core/design_system/app_scale.dart';

/// The colour roles of the design system, derived from whichever palette the
/// user picked in Settings.
///
/// The app ships twelve switchable schemes, so nothing here is a literal: paper
/// steps, rules and inks are all mixed from the active [ColorScheme] toward its
/// own anchor hue. A widget reads a role, never a colour.
@immutable
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  const AppSurfaces({
    required this.paper,
    required this.paper2,
    required this.paper3,
    required this.sheet,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.rule,
    required this.ruleFirm,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.focus,
    required this.onAccent,
    required this.isDark,
  });

  /// The page stock and its two steps down.
  final Color paper;
  final Color paper2;
  final Color paper3;

  /// The printed sheet: the pale stock a hymn's words sit on.
  final Color sheet;

  /// Ink at full weight, ink at rest, and the quiet voice.
  final Color ink;
  final Color ink2;
  final Color muted;

  /// The hairline that parts rows, and the firm rule under a head.
  final Color rule;
  final Color ruleFirm;

  final Color accent;
  final Color accentInk;
  final Color accentSoft;
  final Color focus;

  /// The ink to paint on an accent fill, chosen so the pair always clears 4.5:1.
  final Color onAccent;
  final bool isDark;

  static AppSurfaces from(ColorScheme scheme) {
    final bool dark = scheme.brightness == Brightness.dark;
    final Color paper = scheme.surface;
    final Color ink = scheme.onSurface;

    // Every neutral is tinted toward the anchor; none reaches an absolute.
    final Color paper2 = _mix(paper, scheme.primary, 0.04);
    final Color paper3 = _mix(paper, scheme.primary, 0.10);
    final Color sheet = _shiftLightness(paper, dark ? 0.045 : -0.035);
    final Color ink2 = _mix(ink, paper, 0.12);
    final Color muted = _contrastPair(ink, paper, ink, 7);
    final Color rule = _mix(paper, ink, dark ? 0.14 : 0.08);
    final Color ruleFirm = _mix(paper, ink, dark ? 0.32 : 0.26);
    final Color accentSoft = _mix(paper, scheme.primary, dark ? 0.22 : 0.14);

    return AppSurfaces(
      paper: paper,
      paper2: paper2,
      paper3: paper3,
      sheet: sheet,
      ink: ink,
      ink2: ink2,
      muted: muted,
      rule: rule,
      ruleFirm: ruleFirm,
      accent: scheme.primary,
      accentInk: scheme.onPrimary,
      accentSoft: accentSoft,
      focus: _contrastPair(scheme.primary, paper, scheme.primary, 3),
      onAccent: _bestInk(scheme.primary, paper),
      isDark: dark,
    );
  }

  factory AppSurfaces.of(BuildContext context) =>
      Theme.of(context).extension<AppSurfaces>() ??
      AppSurfaces.from(Theme.of(context).colorScheme);

  /// A fill for a row that is selected, hovered or pressed.
  Color get pressed => _mix(paper, ink, isDark ? 0.10 : 0.05);

  /// The depth of a floating touch control, the one element allowed to lift.
  List<BoxShadow> get floatShadow => [
        BoxShadow(
          color: ink.withValues(alpha: isDark ? 0.5 : 0.14),
          blurRadius: AppScale.blurFloat,
          offset: const Offset(0, AppScale.offsetFloat),
        ),
      ];

  @override
  AppSurfaces copyWith({
    Color? paper,
    Color? paper2,
    Color? paper3,
    Color? sheet,
    Color? ink,
    Color? ink2,
    Color? muted,
    Color? rule,
    Color? ruleFirm,
    Color? accent,
    Color? accentInk,
    Color? accentSoft,
    Color? focus,
    Color? onAccent,
    bool? isDark,
  }) {
    return AppSurfaces(
      paper: paper ?? this.paper,
      paper2: paper2 ?? this.paper2,
      paper3: paper3 ?? this.paper3,
      sheet: sheet ?? this.sheet,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      muted: muted ?? this.muted,
      rule: rule ?? this.rule,
      ruleFirm: ruleFirm ?? this.ruleFirm,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentSoft: accentSoft ?? this.accentSoft,
      focus: focus ?? this.focus,
      onAccent: onAccent ?? this.onAccent,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppSurfaces lerp(covariant AppSurfaces? other, double t) {
    if (other == null) return this;
    return AppSurfaces(
      paper: Color.lerp(paper, other.paper, t)!,
      paper2: Color.lerp(paper2, other.paper2, t)!,
      paper3: Color.lerp(paper3, other.paper3, t)!,
      sheet: Color.lerp(sheet, other.sheet, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      ruleFirm: Color.lerp(ruleFirm, other.ruleFirm, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }

  static Color _mix(Color base, Color over, double amount) =>
      Color.alphaBlend(over.withValues(alpha: amount), base);

  static Color _shiftLightness(Color color, double delta) {
    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + delta).clamp(0.06, 0.97))
        .toColor();
  }

  static double _ratio(Color a, Color b) {
    final double la = a.computeLuminance();
    final double lb = b.computeLuminance();
    final double hi = la > lb ? la : lb;
    final double lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Deepens [probe] toward [fallback] until it clears [target]:1 against [bg].
  static Color _contrastPair(
      Color probe, Color bg, Color fallback, double target) {
    Color out = probe;
    for (int i = 0; i < 12 && _ratio(out, bg) < target; i++) {
      out = _mix(out, fallback, 0.12);
    }
    return out;
  }

  /// The readable ink for an accent fill: whichever of a tinted near-white or a
  /// tinted near-black clears more against it, so a label never sits within a
  /// few percent of its own background.
  static Color _bestInk(Color fill, Color paper) {
    final Color pale = _shiftLightness(paper, 0.94);
    final Color deep = _shiftLightness(paper, 0.12);
    return _ratio(pale, fill) >= _ratio(deep, fill) ? pale : deep;
  }
}
