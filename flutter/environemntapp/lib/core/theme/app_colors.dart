import 'package:flutter/material.dart';

/// Premium nature-inspired color palette for both light and dark themes.
class AppColors {
  AppColors._();

  // Light Mode Base
  static const Color primaryBackground = Color(0xFFF7F5F0); // Warm light beige
  static const Color secondaryBackground = Color(0xFFEBE6DF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color primaryAccent = Color(0xFFC67A4B);
  static const Color secondaryAccent = Color(0xFF8CB369);
  
  static const Color primaryText = Color(0xFF2D2521);
  static const Color secondaryText = Color(0xFF5C534D);
  static const Color mutedText = Color(0xFF8A8A8A);
  
  static const Color dividerColor = Color(0xFFEBE6DF);
  
  static const Color success = Color(0xFF43A047);
  static const Color error = Color(0xFFD32F2F);

  // Dark Mode Base
  static const Color darkPrimaryBackground = Color(0xFF181311);
  static const Color darkSecondaryBackground = Color(0xFF231D1A);
  static const Color darkCardColor = Color(0xFF2D2521);
  static const Color darkPrimaryAccent = primaryAccent;
  static const Color darkSecondaryAccent = secondaryAccent;
  
  static const Color darkPrimaryText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFFCFCFCF);
  static const Color darkMutedText = Color(0xFF8A8A8A);
  static const Color darkSuccess = success;
  static const Color darkError = error;

  // Category Colors
  static const Color climateChange = Color(0xFF42A5F5);
  static const Color recycling = Color(0xFF66BB6A);
  static const Color renewableEnergy = Color(0xFFFFCA28);
  static const Color wildlife = Color(0xFFAB47BC);
  static const Color pollution = Color(0xFFEF5350);
  static const Color sustainableLiving = Color(0xFF26A69A);
  static const Color ecoTips = Color(0xFFFF7043);
  static const Color environmentalNews = Color(0xFF5C6BC0);

  // Air Quality Colors
  static const Color aqiGood = Color(0xFF4CAF50);
  static const Color aqiModerate = Color(0xFFFFEB3B);
  static const Color aqiUnhealthySensitive = Color(0xFFFF9800);
  static const Color aqiUnhealthy = Color(0xFFF44336);
  static const Color aqiVeryUnhealthy = Color(0xFF9C27B0);
  static const Color aqiHazardous = Color(0xFF880E4F);

  static Color getAqiColor(int aqi) {
    if (aqi <= 50) return aqiGood;
    if (aqi <= 100) return aqiModerate;
    if (aqi <= 150) return aqiUnhealthySensitive;
    if (aqi <= 200) return aqiUnhealthy;
    if (aqi <= 300) return aqiVeryUnhealthy;
    return aqiHazardous;
  }

  static String getAqiLabel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }
}
