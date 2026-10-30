import 'package:flutter/material.dart';

import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/app_typography.dart';

/// The single theme recipe. Every surface, control and rule in the app is
/// declared here once, from [AppSurfaces] and [AppTypography]; a screen that
/// wants something different is a screen with a defect.
///
/// Almanac's material: ruled and rounded, never shadowed. No component in this
/// theme casts a shadow except the floating touch chrome, which is the stated
/// exception. Corners follow [AppScale]'s ladder: a control is the tightest,
/// the surface that holds it is wider, a sheet that lifts off the edge widest.
/// The corner ladder, so every shape in the theme is a compile-time constant.
const BorderRadius _control =
    BorderRadius.all(Radius.circular(AppScale.radiusControl));
const BorderRadius _row = BorderRadius.all(Radius.circular(AppScale.radiusRow));
const BorderRadius _surface =
    BorderRadius.all(Radius.circular(AppScale.radiusSurface));
const BorderRadius _mark =
    BorderRadius.all(Radius.circular(AppScale.radiusMark));
const BorderRadius _float =
    BorderRadius.all(Radius.circular(AppScale.radiusFloat));
const BorderRadius _sheetTop =
    BorderRadius.vertical(top: Radius.circular(AppScale.radiusSheet));
const BorderRadius _drawerRight =
    BorderRadius.horizontal(right: Radius.circular(AppScale.radiusSurface));

ThemeData buildFihiranaTheme(ColorScheme scheme, {String? bodyFamily}) {
  final AppSurfaces s = AppSurfaces.from(scheme);
  final TextTheme type = AppTypography.textTheme(s, bodyFamily: bodyFamily);

  OutlineInputBorder fieldEdge(Color color) => OutlineInputBorder(
        borderRadius: _control,
        gapPadding: 0,
        borderSide: BorderSide(color: color, width: AppScale.ruleHair),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: s.paper,
    canvasColor: s.paper,
    primaryColor: s.accent,
    splashFactory: InkRipple.splashFactory,
    highlightColor: s.pressed,
    hoverColor: s.pressed,
    focusColor: s.focus.withValues(alpha: 0.32),
    shadowColor: s.ink.withValues(alpha: 0.12),
    dividerColor: s.rule,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: s.focus,
      selectionColor: s.accentSoft,
      selectionHandleColor: s.accent,
    ),
    extensions: [s],
    textTheme: type,
    primaryTextTheme: type.apply(
      bodyColor: s.onAccent,
      displayColor: s.onAccent,
    ),

    // ---- Chrome -----------------------------------------------------------
    appBarTheme: AppBarTheme(
      backgroundColor: s.paper,
      foregroundColor: s.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: AppScale.gutter,
      titleTextStyle: type.titleLarge,
      iconTheme: IconThemeData(color: s.ink, size: AppScale.iconLg),
      systemOverlayStyle: null,
    ),
    bottomAppBarTheme: BottomAppBarThemeData(
        color: s.paper, elevation: 0, height: AppScale.navBarHeight),
    navigationBarTheme: NavigationBarThemeData(
      height: AppScale.navBarHeight,
      elevation: 0,
      backgroundColor: s.paper,
      surfaceTintColor: Colors.transparent,
      indicatorColor: s.accentSoft,
      indicatorShape: const RoundedRectangleBorder(borderRadius: _control),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          type.labelMedium?.copyWith(
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w400,
              color:
                  states.contains(WidgetState.selected) ? s.accent : s.muted)),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          size: AppScale.iconLg,
          color: states.contains(WidgetState.selected) ? s.accent : s.ink)),
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: s.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: s.accentSoft,
      indicatorShape: const RoundedRectangleBorder(borderRadius: _control),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: s.paper2,
      selectedIconTheme: IconThemeData(color: s.accent),
      unselectedIconTheme: IconThemeData(color: s.ink),
      selectedLabelTextStyle: type.labelMedium?.copyWith(color: s.accent),
      unselectedLabelTextStyle: type.labelMedium?.copyWith(color: s.muted),
      indicatorColor: s.accentSoft,
    ),

    // ---- Surfaces ---------------------------------------------------------
    cardTheme: CardThemeData(
      color: s.paper2,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: _surface),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: s.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: type.headlineSmall,
      contentTextStyle: type.bodyMedium,
      actionsPadding: const EdgeInsets.fromLTRB(
          AppScale.gutter, 0, AppScale.gutter, AppScale.space12),
      shape: const RoundedRectangleBorder(borderRadius: _surface),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: s.paper,
      modalBackgroundColor: s.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: _sheetTop),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: s.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      textStyle: type.bodyMedium,
      menuPadding: const EdgeInsets.symmetric(vertical: AppScale.space8),
      shape: RoundedRectangleBorder(
          side: BorderSide(color: s.rule), borderRadius: _surface),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(s.paper),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            side: BorderSide(color: s.rule), borderRadius: _surface)),
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: s.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: _drawerRight),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: s.ink,
      contentTextStyle: type.bodyMedium?.copyWith(color: s.paper),
      actionTextColor: s.sheet,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.all(AppScale.space16),
      shape: const RoundedRectangleBorder(borderRadius: _control),
    ),
    tooltipTheme: TooltipThemeData(
      decoration:
          BoxDecoration(color: s.paper3, border: Border.all(color: s.rule)),
      padding: const EdgeInsets.symmetric(
          horizontal: AppScale.space8, vertical: AppScale.space4),
      textStyle: type.bodySmall?.copyWith(color: s.ink),
      waitDuration: AppScale.durShort,
    ),
    dividerTheme: DividerThemeData(
      color: s.rule,
      thickness: AppScale.ruleHair,
      space: AppScale.ruleHair,
    ),

    // ---- Controls ---------------------------------------------------------
    // Every button is 48 tall, carries the label dead centre and keeps a
    // buttonGap of air from its neighbours; the four variants differ only in
    // how they are dressed.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(AppScale.space96, AppScale.button),
        padding: const EdgeInsets.symmetric(
            horizontal: AppScale.space24, vertical: AppScale.space12),
        alignment: Alignment.center,
        backgroundColor: s.accent,
        foregroundColor: s.onAccent,
        disabledBackgroundColor: s.paper3,
        disabledForegroundColor: s.muted,
        elevation: 0,
        shadowColor: Colors.transparent,
        textStyle: type.labelLarge,
        shape: const RoundedRectangleBorder(borderRadius: _control),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(AppScale.space96, AppScale.button),
        padding: const EdgeInsets.symmetric(
            horizontal: AppScale.space24, vertical: AppScale.space12),
        alignment: Alignment.center,
        backgroundColor: s.accent,
        foregroundColor: s.onAccent,
        disabledBackgroundColor: s.paper3,
        disabledForegroundColor: s.muted,
        elevation: 0,
        shadowColor: Colors.transparent,
        textStyle: type.labelLarge,
        shape: const RoundedRectangleBorder(borderRadius: _control),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(AppScale.space96, AppScale.button),
        padding: const EdgeInsets.symmetric(
            horizontal: AppScale.space24, vertical: AppScale.space12),
        alignment: Alignment.center,
        foregroundColor: s.ink,
        side: BorderSide(color: s.rule),
        disabledForegroundColor: s.muted,
        elevation: 0,
        textStyle: type.labelLarge,
        shape: const RoundedRectangleBorder(borderRadius: _control),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: s.accent,
        disabledForegroundColor: s.muted,
        minimumSize: const Size(AppScale.space96, AppScale.hitTarget),
        padding: const EdgeInsets.symmetric(
            horizontal: AppScale.space16, vertical: AppScale.space8),
        alignment: Alignment.center,
        tapTargetSize: MaterialTapTargetSize.padded,
        textStyle: type.labelLarge,
        shape: const RoundedRectangleBorder(borderRadius: _control),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: s.ink,
        minimumSize: const Size(AppScale.hitTarget, AppScale.hitTarget),
        padding: const EdgeInsets.all(AppScale.space8),
        tapTargetSize: MaterialTapTargetSize.padded,
        highlightColor: s.pressed,
        shape: const RoundedRectangleBorder(borderRadius: _control),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: s.accent,
      foregroundColor: s.onAccent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: _float),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: s.rule)),
        shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: _control)),
        textStyle: WidgetStatePropertyAll(type.labelMedium),
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? s.accentSoft : s.paper),
        foregroundColor: WidgetStatePropertyAll(s.ink),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: s.ink,
      textColor: s.ink,
      minVerticalPadding: AppScale.space12,
      horizontalTitleGap: 14,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppScale.gutter),
      titleTextStyle: type.bodyLarge,
      subtitleTextStyle: type.bodySmall,
      leadingAndTrailingTextStyle: type.labelMedium,
      shape: const RoundedRectangleBorder(borderRadius: _row),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: false,
      filled: true,
      fillColor: s.sheet,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppScale.space12, vertical: AppScale.space12),
      isCollapsed: false,
      constraints: const BoxConstraints(minHeight: AppScale.field),
      hintStyle: type.bodyMedium?.copyWith(color: s.muted),
      labelStyle: type.bodyMedium?.copyWith(color: s.muted),
      floatingLabelStyle: type.labelMedium?.copyWith(color: s.accent),
      helperStyle: type.bodySmall,
      errorStyle: type.bodySmall
          ?.copyWith(color: scheme.error, fontWeight: FontWeight.w700),
      prefixIconColor: s.muted,
      suffixIconColor: s.muted,
      enabledBorder: fieldEdge(s.rule),
      border: fieldEdge(s.rule),
      focusedBorder: fieldEdge(s.focus),
      errorBorder: fieldEdge(scheme.error),
      focusedErrorBorder: fieldEdge(scheme.error),
      disabledBorder: fieldEdge(s.rule),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? s.accent : s.ink2),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? s.accentSoft : s.paper3),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? s.accent : s.sheet),
      checkColor: WidgetStatePropertyAll(s.onAccent),
      side: BorderSide(color: s.rule),
      shape: const RoundedRectangleBorder(borderRadius: _mark),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? s.accent : s.muted),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: s.accent,
      inactiveTrackColor: s.paper3,
      thumbColor: s.accent,
      overlayColor: s.accent.withValues(alpha: 0.14),
      trackHeight: AppScale.ruleBar * 2,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: s.accent,
      linearTrackColor: s.paper3,
      circularTrackColor: s.paper3,
      linearMinHeight: AppScale.ruleBar,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: s.accent,
      unselectedLabelColor: s.muted,
      labelStyle: type.labelLarge,
      unselectedLabelStyle: type.labelMedium,
      indicatorColor: s.accent,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: s.rule,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: s.paper2,
      selectedColor: s.accentSoft,
      side: BorderSide.none,
      labelStyle: type.labelMedium?.copyWith(color: s.ink),
      shape: const RoundedRectangleBorder(borderRadius: _control),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(
          horizontal: AppScale.space12, vertical: AppScale.space4),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: s.ink,
      collapsedIconColor: s.muted,
      textColor: s.ink,
      collapsedTextColor: s.ink,
      shape: const RoundedRectangleBorder(borderRadius: _row),
    ),
  );
}
