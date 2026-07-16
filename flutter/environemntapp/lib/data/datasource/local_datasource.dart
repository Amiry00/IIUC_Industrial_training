import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../services/database_service.dart';
import '../model/station.dart';

/// Local SQLite data source for stations CRUD and caching.
class LocalDataSource {
  final DatabaseService _dbService;
  const LocalDataSource(this._dbService);

  Future<Database> get _db => _dbService.database;

  // ── READ ──────────────────────────────────────────────────────────
  Future<List<AqStation>> getAllStations() async {
    final db = await _db;
    final maps = await db.query(AppConstants.stationsTable,
        orderBy: 'cached_at DESC');
    return maps.map((m) => AqStation.fromMap(m)).toList();
  }

  Future<List<AqStation>> getStationsPaginated(int page, int pageSize) async {
    final db = await _db;
    final offset = (page - 1) * pageSize;
    final maps = await db.query(AppConstants.stationsTable,
        orderBy: 'id DESC', limit: pageSize, offset: offset);
    return maps.map((m) => AqStation.fromMap(m)).toList();
  }

  Future<AqStation?> getStationById(int id) async {
    final db = await _db;
    final maps = await db.query(AppConstants.stationsTable,
        where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return AqStation.fromMap(maps.first);
  }

  Future<List<AqStation>> searchStations(String query) async {
    final db = await _db;
    final maps = await db.query(AppConstants.stationsTable,
        where: 'name LIKE ? OR country LIKE ? OR country_code LIKE ? OR provider LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
        orderBy: 'id DESC');
    return maps.map((m) => AqStation.fromMap(m)).toList();
  }

  Future<List<AqStation>> getStationsByParameter(String parameterName) async {
    final db = await _db;
    // Search within the JSON-encoded latest_readings for the parameter name
    final maps = await db.query(AppConstants.stationsTable,
        where: 'latest_readings LIKE ?',
        whereArgs: ['%"parameterName":"$parameterName"%'],
        orderBy: 'id DESC');
    return maps.map((m) => AqStation.fromMap(m)).toList();
  }

  Future<List<AqStation>> getFavoriteStations() async {
    final db = await _db;
    final maps = await db.query(AppConstants.stationsTable,
        where: 'is_favorite = 1', orderBy: 'id DESC');
    return maps.map((m) => AqStation.fromMap(m)).toList();
  }

  Future<List<AqStation>> getLocalStations() async {
    final db = await _db;
    final maps = await db.query(AppConstants.stationsTable,
        where: 'is_local = 1', orderBy: 'cached_at DESC');
    return maps.map((m) => AqStation.fromMap(m)).toList();
  }

  Future<int> getStationCount() async {
    final db = await _db;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${AppConstants.stationsTable}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── SEARCH HISTORY ──────────────────────────────────────────────────
  Future<List<String>> getSearchHistory() async {
    final db = await _db;
    final result = await db.query(AppConstants.searchHistoryTable, orderBy: 'timestamp DESC', limit: 10);
    return result.map((row) => row['query'] as String).toList();
  }

  Future<void> addSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    final db = await _db;
    await db.delete(AppConstants.searchHistoryTable, where: 'query = ?', whereArgs: [query.trim()]);
    await db.insert(AppConstants.searchHistoryTable, {
      'query': query.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> clearSearchHistory() async {
    final db = await _db;
    await db.delete(AppConstants.searchHistoryTable);
  }

  // ── CREATE ────────────────────────────────────────────────────────
  Future<AqStation> insertStation(AqStation station) async {
    final db = await _db;
    await db.insert(AppConstants.stationsTable, station.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    debugPrint('[LocalDataSource] Inserted station: ${station.id}');
    return station;
  }

  Future<void> insertStations(List<AqStation> stations) async {
    final db = await _db;
    final batch = db.batch();
    for (final station in stations) {
      // Preserve favorite status for existing stations
      final existing = await getStationById(station.id);
      final stationToInsert = existing != null
          ? station.copyWith(isFavorite: existing.isFavorite, userNotes: existing.userNotes)
          : station;
      batch.insert(AppConstants.stationsTable, stationToInsert.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    debugPrint('[LocalDataSource] Inserted ${stations.length} stations');
  }

  // ── UPDATE ────────────────────────────────────────────────────────
  Future<void> updateStation(AqStation station) async {
    final db = await _db;
    await db.update(AppConstants.stationsTable, station.toMap(),
        where: 'id = ?', whereArgs: [station.id]);
    debugPrint('[LocalDataSource] Updated station: ${station.id}');
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await _db;
    await db.update(
        AppConstants.stationsTable, {'is_favorite': isFavorite ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  // ── DELETE ────────────────────────────────────────────────────────
  Future<void> deleteStation(int id) async {
    final db = await _db;
    await db.delete(AppConstants.stationsTable, where: 'id = ?', whereArgs: [id]);
    debugPrint('[LocalDataSource] Deleted station: $id');
  }

  Future<void> clearAllStations() async {
    final db = await _db;
    await db.delete(AppConstants.stationsTable);
  }

  // ── CACHE META ────────────────────────────────────────────────────
  Future<void> setCacheTimestamp(String key) async {
    final db = await _db;
    await db.insert(
        AppConstants.cacheMetaTable,
        {'cache_key': key, 'cached_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> isCacheValid(String key) async {
    final db = await _db;
    final maps = await db.query(AppConstants.cacheMetaTable,
        where: 'cache_key = ?', whereArgs: [key]);
    if (maps.isEmpty) return false;
    final cachedAt = DateTime.parse(maps.first['cached_at'] as String);
    return DateTime.now().difference(cachedAt).inHours <
        AppConstants.cacheDurationHours;
  }
}
