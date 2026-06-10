/// Application-wide dimension constants to eliminate magic numbers
class AppDimensions {
  // Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Font Sizes
  static const double fontXs = 12.0;
  static const double fontSm = 14.0;
  static const double fontMd = 16.0;
  static const double fontLg = 20.0;
  static const double fontXl = 24.0;
  static const double fontXxl = 32.0;
  static const double fontXxxl = 40.0;

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;

  // Icon Sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // Animation Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 700);

  // Elevation
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 16.0;

  // Opacity
  static const double opacityDisabled = 0.5;
  static const double opacityLow = 0.7;
  static const double opacityMedium = 0.8;
  static const double opacityHigh = 0.9;

  // Layout
  static const double drawerWidth = 280.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 80.0;

  // Limits
  static const int maxHistoryItems = 100;
  static const int maxSearchResults = 50;
  static const int maxCacheSize = 50;
}
