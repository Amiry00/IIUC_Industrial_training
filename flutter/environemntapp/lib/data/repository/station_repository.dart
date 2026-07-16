import 'package:flutter/foundation.dart';
import '../datasource/local_datasource.dart';
import '../datasource/remote_datasource.dart';
import '../model/station.dart';
import '../../core/network/connectivity_service.dart';

class StationRepository {
  final LocalDataSource _local;
  final RemoteDataSource _remote;
  final ConnectivityService _connectivity;

  StationRepository(this._local, this._remote, this._connectivity);

  /// Fetch paginated stations — online-first, then cache.
  Future<List<AqStation>> getStations({int page = 1, int pageSize = 10}) async {
    if (await _connectivity.isConnected) {
      try {
        final apiData = await _remote.getStations(page: page, limit: pageSize);
        if (apiData.isNotEmpty) {
          await _local.insertStations(apiData);
          await _local.setCacheTimestamp('stations');
        }
      } catch (e) {
        debugPrint('[StationRepository] API fetch failed, falling back to cache: $e');
      }
    }
    return _local.getStationsPaginated(page, pageSize);
  }

  /// Get all cached stations.
  Future<List<AqStation>> getAllStations() async {
    return _local.getAllStations();
  }

  /// Search stations by name, country, or provider.
  Future<List<AqStation>> searchStations(String query) async {
    // If online, try to fetch fresh data using Nominatim geocoding + OpenAQ coordinates
    if (await _connectivity.isConnected) {
      try {
        final apiData = await _remote.searchStations(query);
        if (apiData.isNotEmpty) {
          // Cache the search results so they work offline later
          await _local.insertStations(apiData);
          return apiData;
        }
      } catch (e) {
        debugPrint('[StationRepository] API search failed, falling back to cache: $e');
      }
    }
    // Fallback to local SQLite search (matches name, country, provider)
    return _local.searchStations(query);
  }

  /// Get stations near specific coordinates.
  Future<List<AqStation>> getStationsByCoordinates(double lat, double lon) async {
    if (await _connectivity.isConnected) {
      try {
        final stations = await _remote.getStationsByCoordinates(lat, lon);
        if (stations.isNotEmpty) {
          await _local.insertStations(stations);
        }
        return stations;
      } catch (e) {
        debugPrint('[StationRepository] getStationsByCoordinates API failed: $e');
      }
    }
    // Fallback: we could query local db by proximity, but SQLite doesn't have great geospacial queries built-in.
    // For now, return empty if offline.
    return [];
  }

  /// Get stations filtered by a specific air parameter.
  /// Fetches from API first (using parameterId), caches, then falls back to local.
  Future<List<AqStation>> getByParameter(String parameterName, {int parameterId = 0}) async {
    if (await _connectivity.isConnected && parameterId > 0) {
      try {
        final apiData = await _remote.getStationsByParameter(parameterId);
        if (apiData.isNotEmpty) {
          await _local.insertStations(apiData);
          return apiData;
        }
      } catch (e) {
        debugPrint('[StationRepository] getByParameter API failed, falling back to cache: $e');
      }
    }
    return _local.getStationsByParameter(parameterName);
  }

  /// Get a station with its latest readings merged.
  Future<AqStation?> getStationWithLatest(int id) async {
    if (await _connectivity.isConnected) {
      try {
        final station = await _remote.getStationWithLatest(id);
        if (station != null) {
          // Preserve local favorite status
          final local = await _local.getStationById(id);
          final toSave = local != null
              ? station.copyWith(isFavorite: local.isFavorite, userNotes: local.userNotes)
              : station;
          await _local.updateStation(toSave);
          return toSave;
        }
      } catch (e) {
        debugPrint('[StationRepository] getStationWithLatest error: $e');
      }
    }
    return _local.getStationById(id);
  }

  /// Get a single station from local cache.
  Future<AqStation?> getStationById(int id) => _local.getStationById(id);

  /// Get total station count.
  Future<int> getStationCount() => _local.getStationCount();

  // ── Favorites ────────────────────────────────────────────────────
  Future<List<AqStation>> getFavorites() => _local.getFavoriteStations();
  Future<void> toggleFavorite(int id, bool fav) => _local.toggleFavorite(id, fav);



  /// Deep sync: download multiple pages of stations.
  Future<void> refreshFromApi() async {
    if (!await _connectivity.isConnected) return;
    try {
      for (int i = 1; i <= 5; i++) {
        final apiData = await _remote.getStations(page: i, limit: 10);
        if (apiData.isEmpty) break;
        await _local.insertStations(apiData);
      }
      await _local.setCacheTimestamp('stations');
    } catch (e) {
      debugPrint('[StationRepository] deep sync error: $e');
    }
  }
}
