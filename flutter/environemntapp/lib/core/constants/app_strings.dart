/// Centralized UI strings for the Air Quality Monitor app.
class AppStrings {
  AppStrings._();

  // ── App ────────────────────────────────────────────────────────────
  static const String appName = 'Air Quality Monitor';
  static const String appTagline = 'Live Green, Breathe Clean';

  // ── Greeting ───────────────────────────────────────────────────────
  static const String greeting = 'Hello, Eco Explorer!';
  static const String greetingSubtitle = 'Monitor air quality worldwide';

  // ── Navigation ─────────────────────────────────────────────────────
  static const String home = 'Home';
  static const String explore = 'Explore';
  static const String favorites = 'Favorites';
  static const String saved = 'My Notes';
  static const String profile = 'Profile';

  // ── Home Screen ────────────────────────────────────────────────────
  static const String searchHint = 'Search stations, countries...';
  static const String featuredStation = 'Featured Station';
  static const String recentStations = 'Recently Updated';
  static const String globalStations = 'Global Stations';
  static const String airQualityReport = 'Air Quality Report';
  static const String viewAll = 'View All';

  // ── Air Parameters ─────────────────────────────────────────────────
  static const String pm25 = 'PM2.5';
  static const String pm10 = 'PM10';
  static const String pm1 = 'PM1';
  static const String ozone = 'Ozone';
  static const String no2 = 'NO₂';
  static const String so2 = 'SO₂';
  static const String co = 'CO';
  static const String temperature = 'Temperature';
  static const String humidity = 'Humidity';

  // ── Detail Screen ──────────────────────────────────────────────────
  static const String sensorReadings = 'Sensor Readings';
  static const String stationInfo = 'Station Info';
  static const String lastUpdated = 'Last Updated';
  static const String provider = 'Provider';
  static const String share = 'Share';

  // ── CRUD ────────────────────────────────────────────────────────────
  static const String addNote = 'Add Note';
  static const String editNote = 'Edit Note';
  static const String deleteNote = 'Delete Note';
  static const String saveNote = 'Save Note';
  static const String noteTitle = 'Note Title';
  static const String noteContent = 'Note Content';
  static const String stationName = 'Station Name';
  static const String countryName = 'Country';
  static const String deleteConfirmation = 'Are you sure you want to delete this note?';
  static const String deleteSuccess = 'Note deleted successfully';
  static const String saveSuccess = 'Note saved successfully';
  static const String updateSuccess = 'Note updated successfully';

  // ── Error States ───────────────────────────────────────────────────
  static const String noInternet = 'No Internet Connection';
  static const String noInternetMessage = 'Please check your connection and try again.';
  static const String apiError = 'Something Went Wrong';
  static const String apiErrorMessage = 'We couldn\'t load the data. Please try again later.';
  static const String emptyState = 'Nothing Here Yet';
  static const String emptyStateMessage = 'Start exploring air quality stations!';
  static const String emptyFavorites = 'No Favorites Yet';
  static const String emptyFavoritesMessage = 'Tap the heart icon to save your favorite stations.';
  static const String emptySaved = 'No Notes Yet';
  static const String emptySavedMessage = 'Create notes about air quality stations!';
  static const String retry = 'Retry';
  static const String loadingMore = 'Loading more...';
  static const String offlineMode = 'You\'re offline. Showing cached data.';

  // ── AQI Labels ─────────────────────────────────────────────────────
  static const String aqiGood = 'Good';
  static const String aqiModerate = 'Moderate';
  static const String aqiUnhealthySensitive = 'Unhealthy for Sensitive';
  static const String aqiUnhealthy = 'Unhealthy';
  static const String aqiVeryUnhealthy = 'Very Unhealthy';
  static const String aqiHazardous = 'Hazardous';

  // ── Profile ────────────────────────────────────────────────────────
  static const String darkMode = 'Dark Mode';
  static const String savedStations = 'Saved Notes';
  static const String offlineData = 'Offline Data';
  static const String settings = 'Settings';
  static const String about = 'About';
  static const String aboutDescription =
      'Air Quality Monitor is your companion for environmental awareness. '
      'Monitor real-time air quality data from stations worldwide using OpenAQ. '
      'Track PM2.5, PM10, temperature, humidity, and more. '
      'Stay informed and breathe clean!';
  static const String version = 'Version 2.0.0';
  static const String clearCache = 'Clear Cache';
  static const String clearCacheConfirmation = 'Are you sure you want to clear all cached data?';
}
