import 'dart:convert';

/// A single sensor reading from an air quality monitoring station.
class SensorReading {
  final int sensorId;
  final String parameterName; // e.g., pm25, pm10, temperature
  final String displayName; // e.g., PM2.5, PM10, Temperature (C)
  final double value;
  final String units; // e.g., µg/m³, c, %
  final DateTime? datetime;

  const SensorReading({
    required this.sensorId,
    required this.parameterName,
    required this.displayName,
    required this.value,
    required this.units,
    this.datetime,
  });

  /// Create from OpenAQ v3 /locations sensor definition.
  factory SensorReading.fromSensorJson(Map<String, dynamic> json) {
    final param = json['parameter'] as Map<String, dynamic>? ?? {};
    return SensorReading(
      sensorId: json['id'] as int? ?? 0,
      parameterName: param['name'] as String? ?? 'unknown',
      displayName: param['displayName'] as String? ?? param['name'] as String? ?? 'Unknown',
      value: 0, // No value until latest readings are fetched
      units: param['units'] as String? ?? '',
    );
  }

  /// Create from OpenAQ v3 /locations/{id}/latest response item,
  /// cross-referencing sensor metadata.
  factory SensorReading.fromLatestJson(
    Map<String, dynamic> json, {
    required String parameterName,
    required String displayName,
    required String units,
  }) {
    DateTime? dt;
    final dtMap = json['datetime'] as Map<String, dynamic>?;
    if (dtMap != null) {
      dt = DateTime.tryParse(dtMap['utc'] as String? ?? '');
    }
    return SensorReading(
      sensorId: json['sensorsId'] as int? ?? 0,
      parameterName: parameterName,
      displayName: displayName,
      value: (json['value'] as num?)?.toDouble() ?? 0,
      units: units,
      datetime: dt,
    );
  }

  Map<String, dynamic> toJson() => {
        'sensorId': sensorId,
        'parameterName': parameterName,
        'displayName': displayName,
        'value': value,
        'units': units,
        'datetime': datetime?.toIso8601String(),
      };

  factory SensorReading.fromJsonMap(Map<String, dynamic> map) {
    return SensorReading(
      sensorId: map['sensorId'] as int? ?? 0,
      parameterName: map['parameterName'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0,
      units: map['units'] as String? ?? '',
      datetime: map['datetime'] != null ? DateTime.tryParse(map['datetime'] as String) : null,
    );
  }

  SensorReading copyWith({double? value, DateTime? datetime}) {
    return SensorReading(
      sensorId: sensorId,
      parameterName: parameterName,
      displayName: displayName,
      value: value ?? this.value,
      units: units,
      datetime: datetime ?? this.datetime,
    );
  }
}

/// Core station model for air quality monitoring locations.
class AqStation {
  final int id;
  final String name;
  final String country;
  final String countryCode;
  final String provider;
  final double latitude;
  final double longitude;
  final String timezone;
  final bool isMobile;
  final bool isMonitor;
  final List<SensorReading> latestReadings;
  final DateTime? lastUpdated;
  final bool isFavorite;
  final bool isLocal; // user-created station notes
  final String userNotes;

  const AqStation({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    required this.provider,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.isMobile = false,
    this.isMonitor = false,
    this.latestReadings = const [],
    this.lastUpdated,
    this.isFavorite = false,
    this.isLocal = false,
    this.userNotes = '',
  });

  /// Copy with modified fields.
  AqStation copyWith({
    int? id,
    String? name,
    String? country,
    String? countryCode,
    String? provider,
    double? latitude,
    double? longitude,
    String? timezone,
    bool? isMobile,
    bool? isMonitor,
    List<SensorReading>? latestReadings,
    DateTime? lastUpdated,
    bool? isFavorite,
    bool? isLocal,
    String? userNotes,
  }) {
    return AqStation(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      provider: provider ?? this.provider,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      isMobile: isMobile ?? this.isMobile,
      isMonitor: isMonitor ?? this.isMonitor,
      latestReadings: latestReadings ?? this.latestReadings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isFavorite: isFavorite ?? this.isFavorite,
      isLocal: isLocal ?? this.isLocal,
      userNotes: userNotes ?? this.userNotes,
    );
  }

  /// Get the primary PM2.5 reading, if available.
  SensorReading? get pm25Reading =>
      latestReadings.where((r) => r.parameterName == 'pm25').isEmpty
          ? null
          : latestReadings.firstWhere((r) => r.parameterName == 'pm25');

  /// Get the PM10 reading, if available.
  SensorReading? get pm10Reading =>
      latestReadings.where((r) => r.parameterName == 'pm10').isEmpty
          ? null
          : latestReadings.firstWhere((r) => r.parameterName == 'pm10');

  /// Get the temperature reading, if available.
  SensorReading? get temperatureReading =>
      latestReadings.where((r) => r.parameterName == 'temperature').isEmpty
          ? null
          : latestReadings.firstWhere((r) => r.parameterName == 'temperature');

  /// Get the humidity reading, if available.
  SensorReading? get humidityReading =>
      latestReadings.where((r) => r.parameterName == 'relativehumidity').isEmpty
          ? null
          : latestReadings.firstWhere((r) => r.parameterName == 'relativehumidity');

  /// Calculate AQI category from PM2.5 value (US EPA breakpoints).
  int get aqiFromPm25 {
    final pm = pm25Reading?.value ?? 0;
    if (pm <= 12.0) return ((pm / 12.0) * 50).round();
    if (pm <= 35.4) return (50 + ((pm - 12.1) / (35.4 - 12.1)) * 50).round();
    if (pm <= 55.4) return (100 + ((pm - 35.5) / (55.4 - 35.5)) * 50).round();
    if (pm <= 150.4) return (150 + ((pm - 55.5) / (150.4 - 55.5)) * 50).round();
    if (pm <= 250.4) return (200 + ((pm - 150.5) / (250.4 - 150.5)) * 100).round();
    if (pm <= 500.4) return (300 + ((pm - 250.5) / (500.4 - 250.5)) * 200).round();
    return 500;
  }

  /// Convert to map for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'country_code': countryCode,
      'provider': provider,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'is_mobile': isMobile ? 1 : 0,
      'is_monitor': isMonitor ? 1 : 0,
      'latest_readings': jsonEncode(latestReadings.map((r) => r.toJson()).toList()),
      'last_updated': lastUpdated?.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
      'is_local': isLocal ? 1 : 0,
      'user_notes': userNotes,
    };
  }

  /// Create from SQLite map.
  factory AqStation.fromMap(Map<String, dynamic> map) {
    List<SensorReading> readings = [];
    final readingsStr = map['latest_readings'] as String?;
    if (readingsStr != null && readingsStr.isNotEmpty) {
      try {
        final list = jsonDecode(readingsStr) as List;
        readings = list
            .map((e) => SensorReading.fromJsonMap(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return AqStation(
      id: map['id'] as int,
      name: (map['name'] as String?) ?? 'Unknown Station',
      country: (map['country'] as String?) ?? '',
      countryCode: (map['country_code'] as String?) ?? '',
      provider: (map['provider'] as String?) ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      timezone: (map['timezone'] as String?) ?? '',
      isMobile: (map['is_mobile'] as int?) == 1,
      isMonitor: (map['is_monitor'] as int?) == 1,
      latestReadings: readings,
      lastUpdated: map['last_updated'] != null
          ? DateTime.tryParse(map['last_updated'] as String)
          : null,
      isFavorite: (map['is_favorite'] as int?) == 1,
      isLocal: (map['is_local'] as int?) == 1,
      userNotes: (map['user_notes'] as String?) ?? '',
    );
  }

  /// Create from OpenAQ v3 /locations JSON response.
  factory AqStation.fromJson(Map<String, dynamic> json) {
    final countryMap = json['country'] as Map<String, dynamic>? ?? {};
    final providerMap = json['provider'] as Map<String, dynamic>? ?? {};
    final coords = json['coordinates'] as Map<String, dynamic>? ?? {};

    // Parse sensors to get available parameters
    final sensors = json['sensors'] as List? ?? [];
    final readings = sensors
        .map((s) => SensorReading.fromSensorJson(s as Map<String, dynamic>))
        .toList();

    // Try to get the last updated time
    DateTime? lastDt;
    final dtLast = json['datetimeLast'] as Map<String, dynamic>?;
    if (dtLast != null) {
      lastDt = DateTime.tryParse(dtLast['utc'] as String? ?? '');
    } else if (json['datetimeLast'] is String) {
      lastDt = DateTime.tryParse(json['datetimeLast'] as String);
    }

    return AqStation(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      country: countryMap['name'] as String? ?? '',
      countryCode: countryMap['code'] as String? ?? '',
      provider: providerMap['name'] as String? ?? '',
      latitude: (coords['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (coords['longitude'] as num?)?.toDouble() ?? 0,
      timezone: json['timezone'] as String? ?? '',
      isMobile: json['isMobile'] as bool? ?? false,
      isMonitor: json['isMonitor'] as bool? ?? false,
      latestReadings: readings,
      lastUpdated: lastDt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AqStation && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
