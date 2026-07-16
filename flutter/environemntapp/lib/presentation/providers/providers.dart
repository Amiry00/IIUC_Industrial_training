import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/network/dio_client.dart';
import '../../data/datasource/local_datasource.dart';
import '../../data/datasource/remote_datasource.dart';
import '../../data/model/station.dart';
import '../../data/model/air_parameter.dart';
import '../../data/repository/station_repository.dart';
import '../../services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repository/auth_repository.dart';
import '../../data/model/user.dart';
import '../../services/notification_service.dart';
import '../../data/repository/notification_repository.dart';
import '../../data/model/notification_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';

// ── Service Providers ───────────────────────────────────────────────
final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());
final dioClientProvider = Provider<DioClient>((ref) => DioClient());
final connectivityServiceProvider = Provider<ConnectivityService>((ref) => ConnectivityService());
final localDataSourceProvider = Provider<LocalDataSource>((ref) => LocalDataSource(ref.read(databaseServiceProvider)));
final remoteDataSourceProvider = Provider<RemoteDataSource>((ref) => RemoteDataSource(ref.read(dioClientProvider)));
final stationRepositoryProvider = Provider<StationRepository>((ref) => StationRepository(ref.read(localDataSourceProvider), ref.read(remoteDataSourceProvider), ref.read(connectivityServiceProvider)));
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.read(databaseServiceProvider)));
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => NotificationRepository(ref.read(databaseServiceProvider)));
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

// ── Auth Provider ───────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider), ref.read(sharedPreferencesProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _authRepo;
  final SharedPreferences _prefs;
  static const _sessionKey = 'session_user_id';

  AuthNotifier(this._authRepo, this._prefs) : super(const AsyncValue.loading()) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final userId = _prefs.getInt(_sessionKey);
    if (userId != null) {
      try {
        final user = await _authRepo.getUserById(userId);
        state = AsyncValue.data(user);
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepo.login(email, password);
      await _prefs.setInt(_sessionKey, user.id);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepo.register(name, email, password);
      await _prefs.setInt(_sessionKey, user.id);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _prefs.remove(_sessionKey);
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile(User user) async {
    try {
      final updatedUser = await _authRepo.updateProfile(user);
      state = AsyncValue.data(updatedUser);
    } catch (e, st) {
      // Don't change state on error for profile update, just throw
      rethrow;
    }
  }
}

// ── Notifications Provider ────────────────────────────────────────────
final notificationsProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<AppNotification>>>((ref) {
  return NotificationNotifier(ref.read(notificationRepositoryProvider));
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final NotificationRepository _repo;

  NotificationNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      final notifs = await _repo.getNotifications();
      state = AsyncValue.data(notifs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addNotification(String title, String body, String type) async {
    try {
      final notif = AppNotification(
        id: 0,
        title: title,
        body: body,
        type: type,
        timestamp: DateTime.now(),
      );
      await _repo.addNotification(notif);
      await load();
    } catch (e) {
      debugPrint('Failed to add notification: $e');
    }
  }

  Future<void> markAsRead(int id) async {
    await _repo.markAsRead(id);
    await load();
  }

  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead();
    await load();
  }

  Future<void> delete(int id) async {
    await _repo.deleteNotification(id);
    await load();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    await load();
  }
}

// ── Location AQI Provider ───────────────────────────────────────────
final currentLocationAqProvider = FutureProvider<AqStation?>((ref) async {
  // Skip geolocation on desktop platforms — no GPS available and Geolocator hangs
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    return null;
  }

  bool serviceEnabled;
  LocationPermission permission;

  try {
    serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(const Duration(seconds: 2));
  } catch (_) {
    serviceEnabled = false;
  }
  
  if (!serviceEnabled) {
    return null;
  }

  try {
    permission = await Geolocator.checkPermission().timeout(const Duration(seconds: 2));
  } catch (_) {
    return null;
  }
  if (permission == LocationPermission.denied) {
    try {
      permission = await Geolocator.requestPermission().timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
    if (permission == LocationPermission.denied) {
      return null;
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    return null;
  } 

  try {
    final position = await Geolocator.getCurrentPosition(
      timeLimit: const Duration(seconds: 5),
    );
    final repo = ref.read(stationRepositoryProvider);
    final stations = await repo.getStationsByCoordinates(position.latitude, position.longitude);
    
    if (stations.isNotEmpty) {
      return stations.first;
    }
  } catch (e) {
    debugPrint('[currentLocationAqProvider] Location or API error: $e');
  }
  return null;
});

// ── Recently Viewed Provider ───────────────────────────────────────────
final recentlyViewedProvider = StateNotifierProvider<RecentlyViewedNotifier, List<AqStation>>((ref) {
  return RecentlyViewedNotifier(ref.read(stationRepositoryProvider), ref.read(databaseServiceProvider));
});

class RecentlyViewedNotifier extends StateNotifier<List<AqStation>> {
  final StationRepository _repo;
  final DatabaseService _dbService;

  RecentlyViewedNotifier(this._repo, this._dbService) : super([]) {
    load();
  }

  Future<void> load() async {
    final db = await _dbService.database;
    final result = await db.query('recently_viewed', orderBy: 'timestamp DESC', limit: 10);
    
    final List<AqStation> stations = [];
    for (var row in result) {
      final id = row['station_id'] as int;
      final station = await _repo.getStationById(id);
      if (station != null) stations.add(station);
    }
    state = stations;
  }

  Future<void> add(int stationId) async {
    final db = await _dbService.database;
    await db.insert(
      'recently_viewed',
      {'station_id': stationId, 'timestamp': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await load();
  }
}

// ── Search History Provider ───────────────────────────────────────────
final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier(ref.read(localDataSourceProvider));
});

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  final LocalDataSource _local;

  SearchHistoryNotifier(this._local) : super([]) {
    load();
  }

  Future<void> load() async {
    state = await _local.getSearchHistory();
  }

  Future<void> add(String query) async {
    await _local.addSearchHistory(query);
    await load();
  }

  Future<void> clear() async {
    await _local.clearSearchHistory();
    await load();
  }
}

// ── Theme Provider ──────────────────────────────────────────────────
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) => ThemeNotifier());

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light);
  void toggle() => state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  bool get isDark => state == ThemeMode.dark;
}

// ── Connectivity Provider ───────────────────────────────────────────
final isConnectedProvider = FutureProvider<bool>((ref) async {
  return ref.read(connectivityServiceProvider).isConnected;
});

// ── Stations State ──────────────────────────────────────────────────
class StationsState {
  final List<AqStation> stations;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const StationsState({
    this.stations = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  StationsState copyWith({List<AqStation>? stations, bool? isLoading, bool? isLoadingMore, String? error, int? currentPage, bool? hasMore}) {
    return StationsState(
      stations: stations ?? this.stations,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ── Stations Notifier ───────────────────────────────────────────────
final stationsProvider = StateNotifierProvider<StationsNotifier, StationsState>((ref) {
  return StationsNotifier(ref.read(stationRepositoryProvider));
});

class StationsNotifier extends StateNotifier<StationsState> {
  final StationRepository _repository;
  StationsNotifier(this._repository) : super(const StationsState()) {
    loadStations();
  }

  Future<void> loadStations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Optimistic fast load from local cache
      final localStations = await _repository.getAllStations();
      if (localStations.isNotEmpty) {
        state = state.copyWith(
          stations: localStations.take(10).toList(), 
          isLoading: false, 
          currentPage: 1, 
          hasMore: localStations.length >= 10
        );
      }
      
      // 2. Fetch fresh from API
      final stations = await _repository.getStations(page: 1, pageSize: 10);
      state = state.copyWith(
        stations: stations, 
        isLoading: false, 
        currentPage: 1, 
        hasMore: stations.length >= 10
      );
    } catch (e) {
      if (state.stations.isEmpty) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final more = await _repository.getStations(page: nextPage, pageSize: 10);
      state = state.copyWith(
        stations: [...state.stations, ...more],
        isLoadingMore: false,
        currentPage: nextPage,
        hasMore: more.length >= 10,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await _repository.refreshFromApi();
    await loadStations();
  }
}

// ── Search Provider ─────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<AqStation>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  
  final results = await ref.read(stationRepositoryProvider).searchStations(query);
  if (results.isNotEmpty) {
    Future.microtask(() => ref.read(searchHistoryProvider.notifier).add(query));
  }
  return results;
});

// ── Parameter Filter ────────────────────────────────────────────────
final selectedParameterProvider = StateProvider<AirParameter?>((ref) => null);

final parameterStationsProvider = FutureProvider<List<AqStation>>((ref) async {
  final parameter = ref.watch(selectedParameterProvider);
  if (parameter == null || parameter == AirParameter.all) {
    return ref.read(stationRepositoryProvider).getAllStations();
  }
  return ref.read(stationRepositoryProvider).getByParameter(
    parameter.apiName,
    parameterId: parameter.apiId,
  );
});

// ── Station Detail (with latest readings) ───────────────────────────
final stationDetailProvider = FutureProvider.family<AqStation?, int>((ref, id) async {
  return ref.read(stationRepositoryProvider).getStationWithLatest(id);
});

// ── Favorites ───────────────────────────────────────────────────────
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<AqStation>>((ref) {
  return FavoritesNotifier(ref.read(stationRepositoryProvider));
});

class FavoritesNotifier extends StateNotifier<List<AqStation>> {
  final StationRepository _repo;
  FavoritesNotifier(this._repo) : super([]) { load(); }

  Future<void> load() async {
    state = await _repo.getFavorites();
  }

  Future<void> toggle(AqStation station) async {
    final newFav = !station.isFavorite;
    await _repo.toggleFavorite(station.id, newFav);
    await load();
  }

  bool isFavorite(int id) => state.any((s) => s.id == id);
}



// ── Bottom Nav ──────────────────────────────────────────────────────
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
