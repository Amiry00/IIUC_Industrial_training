import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static bool isDark = true;

  // CineVault Premium Light/Dark Theme Colors
  static Color get background => isDark ? const Color(0xFF0E0E10) : const Color(0xFFFAF8F5);
  static Color get surface => isDark ? const Color(0xFF17181C) : const Color(0xFFFFFFFF);
  static Color get card => isDark ? const Color(0xFF23252B) : const Color(0xFFFFFFFF);
  static const Color primaryAccent = Color(0xFFC67A4B);
  static const Color secondaryAccent = Color(0xFFE0A458);
  static Color get primaryText => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF2C2420);
  static Color get secondaryText => isDark ? const Color(0xFFC8C8C8) : const Color(0xFF8D7B68);
  static Color get mutedText => isDark ? const Color(0xFF7C7C7C) : const Color(0xFFB5A596);
  static Color get divider => isDark ? const Color(0xFF32353C) : const Color(0xFFEFEBE6);
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFFF5D5D);

  // Gradient colors
  static LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, background],
    stops: const [0.3, 1.0],
  );

  static LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, isDark ? const Color(0xCC0E0E10) : const Color(0xCCFFFFFF)],
    stops: const [0.5, 1.0],
  );

  static LinearGradient get accentGradient => const LinearGradient(
    colors: [primaryAccent, secondaryAccent],
  );
}

class AppDimensions {
  AppDimensions._();

  static const double cardRadius = 18.0;
  static const double buttonRadius = 14.0;
  static const double chipRadius = 20.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXL = 32.0;
  static const double posterAspectRatio = 2 / 3;
  static const double heroHeight = 0.55;
  static const double bottomNavHeight = 64.0;
}

class AppStrings {
  AppStrings._();

  static const String appName = 'Cinema';
  static const String tagline = 'Your Cinema, Anywhere';
  static const String trending = 'Trending Now';
  static const String popular = 'Popular Movies';
  static const String topRated = 'Top Rated';
  static const String nowPlaying = 'Now Playing';
  static const String upcoming = 'Upcoming';
  static const String searchHint = 'Search movies...';
  static const String watchlist = 'My Watchlist';
  static const String noInternet = 'No internet connection';
  static const String apiError = 'Something went wrong';
  static const String emptyState = 'No movies found';
  static const String retry = 'Retry';
}
