import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/network/dio_client.dart';
import '../model/station.dart';

/// Remote data source for OpenAQ v3 API.
class RemoteDataSource {
  final DioClient _dioClient;

  /// Cached country list for search (code → name mapping).
  List<Map<String, dynamic>>? _countriesCache;

  RemoteDataSource(this._dioClient);

  /// Fetch a paginated list of air quality monitoring stations with latest readings.
  Future<List<AqStation>> getStations({int page = 1, int limit = 10}) async {
    try {
      final response = await _dioClient.get('/locations', queryParameters: {
        'page': page,
        'limit': limit,
        'order_by': 'id',
        'sort_order': 'desc',
      });

      final data = response.data as Map<String, dynamic>? ?? {};
      final results = data['results'] as List? ?? [];

      final stations = results
          .map((json) => AqStation.fromJson(json as Map<String, dynamic>))
          .toList();

      // Enrich each station with latest readings (individual errors won't crash the list)
      return _enrichWithLatest(stations);
    } catch (e) {
      debugPrint('[RemoteDataSource] getStations error: $e');
      rethrow;
    }
  }

  /// Fetch latest sensor readings for a specific station.
  Future<List<SensorReading>> getStationLatest(int locationId) async {
    try {
      final response = await _dioClient.get('/locations/$locationId/latest');

      final data = response.data as Map<String, dynamic>? ?? {};
      final results = data['results'] as List? ?? [];

      return results.map((json) {
        final map = json as Map<String, dynamic>;
        return SensorReading(
          sensorId: map['sensorsId'] as int? ?? 0,
          parameterName: '',
          displayName: '',
          value: (map['value'] as num?)?.toDouble() ?? 0,
          units: '',
          datetime: _parseDateTime(map['datetime']),
        );
      }).toList();
    } catch (e) {
      debugPrint('[RemoteDataSource] getStationLatest error: $e');
      rethrow;
    }
  }

  /// Fetch a single station's details with sensor metadata.
  Future<AqStation?> getStationById(int locationId) async {
    try {
      final response = await _dioClient.get('/locations/$locationId');

      final data = response.data as Map<String, dynamic>? ?? {};
      final results = data['results'] as List? ?? [];

      if (results.isEmpty) return null;
      return AqStation.fromJson(results.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[RemoteDataSource] getStationById error: $e');
      rethrow;
    }
  }

  /// Fetch station with its latest readings merged.
  Future<AqStation?> getStationWithLatest(int locationId) async {
    try {
      // 1. Get station metadata
      final station = await getStationById(locationId);
      if (station == null) return null;

      // 2. Get latest readings
      final latestResponse =
          await _dioClient.get('/locations/$locationId/latest');
      final latestData = latestResponse.data as Map<String, dynamic>? ?? {};
      final latestResults = latestData['results'] as List? ?? [];

      // 3. Build sensor ID → metadata map from station's sensors
      final sensorMap = <int, SensorReading>{};
      for (final reading in station.latestReadings) {
        sensorMap[reading.sensorId] = reading;
      }

      // 4. Merge latest values into sensor metadata
      final mergedReadings = <SensorReading>[];
      for (final item in latestResults) {
        final map = item as Map<String, dynamic>;
        final sensorId = map['sensorsId'] as int? ?? 0;
        final meta = sensorMap[sensorId];
        if (meta != null) {
          mergedReadings.add(meta.copyWith(
            value: (map['value'] as num?)?.toDouble() ?? 0,
            datetime: _parseDateTime(map['datetime']),
          ));
        }
      }

      return station.copyWith(
        latestReadings: mergedReadings,
        lastUpdated:
            mergedReadings.isNotEmpty ? mergedReadings.first.datetime : null,
      );
    } catch (e) {
      debugPrint('[RemoteDataSource] getStationWithLatest error: $e');
      return null; // Return null instead of rethrowing — so one failure doesn't crash the list
    }
  }

  /// Fetch countries with monitoring data (cached after first call).
  Future<List<Map<String, dynamic>>> getCountries() async {
    if (_countriesCache != null) return _countriesCache!;
    try {
      final response =
          await _dioClient.get('/countries', queryParameters: {'limit': 200});
      final data = response.data as Map<String, dynamic>? ?? {};
      final results = data['results'] as List? ?? [];
      _countriesCache = results.cast<Map<String, dynamic>>();
      return _countriesCache!;
    } catch (e) {
      debugPrint('[RemoteDataSource] getCountries error: $e');
      rethrow;
    }
  }

  /// Search stations (OpenAQ doesn't have a direct name search, so we use
  /// the /locations endpoint with parameters_id for parameter-based filtering).
  Future<List<AqStation>> getStationsByParameter(int parameterId,
      {int page = 1, int limit = 10}) async {
    try {
      final response = await _dioClient.get('/locations', queryParameters: {
        'parameters_id': parameterId,
        'page': page,
        'limit': limit,
        'order_by': 'id',
        'sort_order': 'desc',
      });

      final data = response.data as Map<String, dynamic>? ?? {};
      final results = data['results'] as List? ?? [];
      final stations = results
          .map((json) => AqStation.fromJson(json as Map<String, dynamic>))
          .toList();

      return _enrichWithLatest(stations);
    } catch (e) {
      debugPrint('[RemoteDataSource] getStationsByParameter error: $e');
      rethrow;
    }
  }

  /// Search stations by country name, city, or station name.
  /// Strategy:
  ///   1. Try matching query to a country name/code → use OpenAQ `iso` param
  ///   2. Also try Nominatim geocoding → use OpenAQ `coordinates` + `radius`
  ///   3. Return combined results
  Future<List<AqStation>> searchStations(String query) async {
    final allStations = <AqStation>[];
    final seenIds = <int>{};

    try {
      // ── Strategy 1: Match to country ISO code ──────────────────
      final isoCode = await _resolveCountryCode(query);
      if (isoCode != null) {
        debugPrint('[RemoteDataSource] Searching by country: $isoCode');
        final response = await _dioClient.get('/locations', queryParameters: {
          'iso': isoCode,
          'limit': 50,
          'order_by': 'id',
          'sort_order': 'desc',
        });
        final data = response.data as Map<String, dynamic>? ?? {};
        final results = data['results'] as List? ?? [];
        for (final json in results) {
          final s = AqStation.fromJson(json as Map<String, dynamic>);
          if (seenIds.add(s.id)) allStations.add(s);
        }
      }

      // ── Strategy 2: Geocode → coordinates search ───────────────
      if (allStations.length < 5) {
        try {
          final geoResponse = await Dio().get(
            'https://nominatim.openstreetmap.org/search',
            queryParameters: {'q': query, 'format': 'json', 'limit': 1},
            options: Options(headers: {'User-Agent': 'AirQualityMonitorApp/1.0'}),
          );

          final geoData = geoResponse.data as List? ?? [];
          if (geoData.isNotEmpty) {
            final lat = double.tryParse(geoData.first['lat'] as String? ?? '');
            final lon = double.tryParse(geoData.first['lon'] as String? ?? '');

            if (lat != null && lon != null) {
              final response =
                  await _dioClient.get('/locations', queryParameters: {
                'coordinates': '$lat,$lon',
                'radius': 250000, // 250km radius
                'limit': 50,
                'order_by': 'id',
                'sort_order': 'desc',
              });
              final data = response.data as Map<String, dynamic>? ?? {};
              final results = data['results'] as List? ?? [];
              for (final json in results) {
                final s = AqStation.fromJson(json as Map<String, dynamic>);
                if (seenIds.add(s.id)) allStations.add(s);
              }
            }
          }
        } catch (e) {
          debugPrint('[RemoteDataSource] Nominatim search failed: $e');
        }
      }

      // Enrich with latest readings
      if (allStations.isNotEmpty) {
        return _enrichWithLatest(allStations);
      }

      return [];
    } catch (e) {
      debugPrint('[RemoteDataSource] searchStations error: $e');
      return [];
    }
  }

  /// Get stations near specific coordinates.
  Future<List<AqStation>> getStationsByCoordinates(double lat, double lon, {int radius = 25000, int limit = 10}) async {
    try {
      final response = await _dioClient.get('/locations', queryParameters: {
        'coordinates': '$lat,$lon',
        'radius': radius,
        'limit': limit,
        'order_by': 'id',
        'sort_order': 'desc',
      });
      final data = response.data as Map<String, dynamic>? ?? {};
      final results = data['results'] as List? ?? [];
      final stations = results
          .map((json) => AqStation.fromJson(json as Map<String, dynamic>))
          .toList();

      return _enrichWithLatest(stations);
    } catch (e) {
      debugPrint('[RemoteDataSource] getStationsByCoordinates error: $e');
      return [];
    }
  }

  /// Resolve a user query to a 2-letter ISO country code.
  /// Matches against country names from the OpenAQ /countries endpoint.
  Future<String?> _resolveCountryCode(String query) async {
    final q = query.trim().toLowerCase();

    // Common abbreviations / short codes
    final directMap = {
      'bd': 'BD', 'bangladesh': 'BD',
      'in': 'IN', 'india': 'IN',
      'pk': 'PK', 'pakistan': 'PK',
      'cn': 'CN', 'china': 'CN',
      'us': 'US', 'usa': 'US', 'united states': 'US', 'america': 'US',
      'uk': 'GB', 'united kingdom': 'GB', 'england': 'GB', 'britain': 'GB',
      'jp': 'JP', 'japan': 'JP',
      'de': 'DE', 'germany': 'DE',
      'fr': 'FR', 'france': 'FR',
      'br': 'BR', 'brazil': 'BR',
      'au': 'AU', 'australia': 'AU',
      'ca': 'CA', 'canada': 'CA',
      'sa': 'SA', 'saudi arabia': 'SA',
      'ae': 'AE', 'uae': 'AE', 'united arab emirates': 'AE',
      'np': 'NP', 'nepal': 'NP',
      'lk': 'LK', 'sri lanka': 'LK',
      'mm': 'MM', 'myanmar': 'MM',
      'th': 'TH', 'thailand': 'TH',
      'id': 'ID', 'indonesia': 'ID',
      'my': 'MY', 'malaysia': 'MY',
      'sg': 'SG', 'singapore': 'SG',
      'kr': 'KR', 'south korea': 'KR', 'korea': 'KR',
      'ng': 'NG', 'nigeria': 'NG',
      'eg': 'EG', 'egypt': 'EG',
      'za': 'ZA', 'south africa': 'ZA',
      'ke': 'KE', 'kenya': 'KE',
      'mx': 'MX', 'mexico': 'MX',
      'ru': 'RU', 'russia': 'RU',
      'it': 'IT', 'italy': 'IT',
      'es': 'ES', 'spain': 'ES',
      'tr': 'TR', 'turkey': 'TR',
    };

    if (directMap.containsKey(q)) return directMap[q];

    // Try fuzzy match against the OpenAQ countries list
    try {
      final countries = await getCountries();
      for (final c in countries) {
        final name = (c['name'] as String? ?? '').toLowerCase();
        final code = (c['code'] as String? ?? '').toLowerCase();
        if (name == q || code == q || name.contains(q) || q.contains(name)) {
          return (c['code'] as String?)?.toUpperCase();
        }
      }
    } catch (e) {
      debugPrint('[RemoteDataSource] Country resolution failed: $e');
    }

    return null;
  }

  /// Enrich a list of stations with their latest readings.
  /// Individual failures are caught — a single station's latest-fetch failure
  /// won't crash the entire list.
  Future<List<AqStation>> _enrichWithLatest(List<AqStation> stations) async {
    final futures = stations.map((station) async {
      try {
        final latestResponse =
            await _dioClient.get('/locations/${station.id}/latest');
        final latestData =
            latestResponse.data as Map<String, dynamic>? ?? {};
        final latestResults = latestData['results'] as List? ?? [];

        if (latestResults.isEmpty) return station;

        // Build sensor ID → metadata map
        final sensorMap = <int, SensorReading>{};
        for (final reading in station.latestReadings) {
          sensorMap[reading.sensorId] = reading;
        }

        // Merge latest values
        final mergedReadings = <SensorReading>[];
        for (final item in latestResults) {
          final map = item as Map<String, dynamic>;
          final sensorId = map['sensorsId'] as int? ?? 0;
          final meta = sensorMap[sensorId];
          if (meta != null) {
            mergedReadings.add(meta.copyWith(
              value: (map['value'] as num?)?.toDouble() ?? 0,
              datetime: _parseDateTime(map['datetime']),
            ));
          }
        }

        return station.copyWith(
          latestReadings:
              mergedReadings.isNotEmpty ? mergedReadings : station.latestReadings,
          lastUpdated:
              mergedReadings.isNotEmpty ? mergedReadings.first.datetime : null,
        );
      } catch (e) {
        debugPrint('[RemoteDataSource] enrichLatest failed for ${station.id}: $e');
        return station; // Return station without latest on failure
      }
    }).toList();

    return Future.wait(futures);
  }

  DateTime? _parseDateTime(dynamic dtField) {
    if (dtField is Map<String, dynamic>) {
      return DateTime.tryParse(dtField['utc'] as String? ?? '');
    }
    if (dtField is String) {
      return DateTime.tryParse(dtField);
    }
    return null;
  }
}
