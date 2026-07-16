/// Application-wide constants for the Air Quality Monitor app.
class AppConstants {
  AppConstants._();

  // ── API Configuration ──────────────────────────────────────────────
  /// OpenAQ v3 API base URL.
  static const String apiBaseUrl = 'https://api.openaq.org/v3';

  /// OpenAQ API key (sent via X-API-Key header).
  static const String apiKey =
      '373072a37541eb2a12ad3f4a4c1538b16d1f2a1f66c2c9a8c5e9027954cc03a8';

  // ── Pagination ─────────────────────────────────────────────────────
  static const int pageSize = 10;
  static const int initialPage = 1;

  // ── Debounce ───────────────────────────────────────────────────────
  static const int searchDebounceDuration = 500; // milliseconds

  // ── Cache ──────────────────────────────────────────────────────────
  static const int cacheDurationHours = 24;

  // ── Database ───────────────────────────────────────────────────────
  static const String databaseName = 'air_quality_monitor.db';
  static const int databaseVersion = 3; // Bumped for production upgrade

  // ── Tables ─────────────────────────────────────────────────────────
  static const String stationsTable = 'stations';
  static const String cacheMetaTable = 'cache_meta';
  static const String usersTable = 'users';
  static const String notificationsTable = 'notifications';
  static const String searchHistoryTable = 'search_history';
  static const String recentlyViewedTable = 'recently_viewed';
  static const String settingsTable = 'settings';

  // ── Animation Durations ────────────────────────────────────────────
  static const int splashDuration = 3000; // milliseconds
  static const int animationDuration = 300;
  static const int staggerDelay = 100;
}
