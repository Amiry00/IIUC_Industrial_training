import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Air quality parameters for filtering stations.
enum AirParameter {
  all,
  pm25,
  pm10,
  pm1,
  o3,
  no2,
  so2,
  co,
  temperature,
  humidity,
}

/// Extension on AirParameter for display properties.
extension AirParameterExtension on AirParameter {
  /// Display name for the parameter.
  String get displayName {
    switch (this) {
      case AirParameter.all:
        return 'All';
      case AirParameter.pm25:
        return 'PM2.5';
      case AirParameter.pm10:
        return 'PM10';
      case AirParameter.pm1:
        return 'PM1';
      case AirParameter.o3:
        return 'Ozone';
      case AirParameter.no2:
        return 'NO₂';
      case AirParameter.so2:
        return 'SO₂';
      case AirParameter.co:
        return 'CO';
      case AirParameter.temperature:
        return 'Temperature';
      case AirParameter.humidity:
        return 'Humidity';
    }
  }

  /// API parameter name used in OpenAQ.
  String get apiName {
    switch (this) {
      case AirParameter.all:
        return '';
      case AirParameter.pm25:
        return 'pm25';
      case AirParameter.pm10:
        return 'pm10';
      case AirParameter.pm1:
        return 'pm1';
      case AirParameter.o3:
        return 'o3';
      case AirParameter.no2:
        return 'no2';
      case AirParameter.so2:
        return 'so2';
      case AirParameter.co:
        return 'co';
      case AirParameter.temperature:
        return 'temperature';
      case AirParameter.humidity:
        return 'relativehumidity';
    }
  }

  /// OpenAQ v3 parameter ID for API queries.
  int get apiId {
    switch (this) {
      case AirParameter.all:
        return 0;
      case AirParameter.pm25:
        return 2;
      case AirParameter.pm10:
        return 1;
      case AirParameter.pm1:
        return 19;
      case AirParameter.o3:
        return 3;
      case AirParameter.no2:
        return 7;
      case AirParameter.so2:
        return 9;
      case AirParameter.co:
        return 8;
      case AirParameter.temperature:
        return 100;
      case AirParameter.humidity:
        return 98;
    }
  }

  /// Color for the parameter badge.
  Color get color {
    switch (this) {
      case AirParameter.all:
        return AppColors.primaryAccent;
      case AirParameter.pm25:
        return AppColors.aqiUnhealthy;
      case AirParameter.pm10:
        return AppColors.aqiUnhealthySensitive;
      case AirParameter.pm1:
        return AppColors.aqiModerate;
      case AirParameter.o3:
        return AppColors.climateChange;
      case AirParameter.no2:
        return AppColors.pollution;
      case AirParameter.so2:
        return AppColors.aqiVeryUnhealthy;
      case AirParameter.co:
        return AppColors.aqiHazardous;
      case AirParameter.temperature:
        return AppColors.renewableEnergy;
      case AirParameter.humidity:
        return AppColors.wildlife;
    }
  }

  /// Icon for the parameter.
  IconData get icon {
    switch (this) {
      case AirParameter.all:
        return Icons.dashboard_rounded;
      case AirParameter.pm25:
        return Icons.grain_rounded;
      case AirParameter.pm10:
        return Icons.blur_on_rounded;
      case AirParameter.pm1:
        return Icons.blur_circular_rounded;
      case AirParameter.o3:
        return Icons.cloud_outlined;
      case AirParameter.no2:
        return Icons.factory_outlined;
      case AirParameter.so2:
        return Icons.science_outlined;
      case AirParameter.co:
        return Icons.local_fire_department_outlined;
      case AirParameter.temperature:
        return Icons.thermostat_outlined;
      case AirParameter.humidity:
        return Icons.water_drop_outlined;
    }
  }

  /// Emoji for the parameter.
  String get emoji {
    switch (this) {
      case AirParameter.all:
        return '🌍';
      case AirParameter.pm25:
        return '🫁';
      case AirParameter.pm10:
        return '💨';
      case AirParameter.pm1:
        return '🔬';
      case AirParameter.o3:
        return '🌤️';
      case AirParameter.no2:
        return '🏭';
      case AirParameter.so2:
        return '⚗️';
      case AirParameter.co:
        return '🔥';
      case AirParameter.temperature:
        return '🌡️';
      case AirParameter.humidity:
        return '💧';
    }
  }

  /// Unit string for the parameter.
  String get unit {
    switch (this) {
      case AirParameter.all:
        return '';
      case AirParameter.pm25:
      case AirParameter.pm10:
      case AirParameter.pm1:
      case AirParameter.o3:
      case AirParameter.no2:
      case AirParameter.so2:
      case AirParameter.co:
        return 'µg/m³';
      case AirParameter.temperature:
        return '°C';
      case AirParameter.humidity:
        return '%';
    }
  }

  /// Convert to string for database storage.
  String get toDbString => name;

  /// Create from database string.
  static AirParameter fromString(String value) {
    return AirParameter.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AirParameter.all,
    );
  }
}
