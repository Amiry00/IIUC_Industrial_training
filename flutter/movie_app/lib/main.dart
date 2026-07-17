import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:media_kit/media_kit.dart';

import 'package:cinema/core/constants/app_constants.dart';
import 'package:cinema/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cinema/services/api_service.dart';
import 'package:cinema/services/database_service.dart';
import 'package:cinema/services/connectivity_service.dart';
import 'package:cinema/data/repository/movie_repository.dart';
import 'package:cinema/providers/movie_provider.dart';
import 'package:cinema/providers/search_provider.dart';
import 'package:cinema/providers/detail_provider.dart';
import 'package:cinema/providers/watchlist_provider.dart';
import 'package:cinema/providers/theme_provider.dart';
import 'package:cinema/providers/auth_provider.dart';
import 'package:cinema/presentation/screens/splash/splash_screen.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Services
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  getIt.registerLazySingleton<DatabaseService>(() => DatabaseService());
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  // Repository
  getIt.registerLazySingleton<MovieRepository>(() => MovieRepository(
        apiService: getIt<ApiService>(),
        dbService: getIt<DatabaseService>(),
        connectivityService: getIt<ConnectivityService>(),
      ));
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  GoogleFonts.config.allowRuntimeFetching = true;
  setupDependencies();
  runApp(const CinemaApp());
}

class CinemaApp extends StatelessWidget {
  const CinemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(getIt<DatabaseService>())),
        ChangeNotifierProvider(create: (_) => MovieProvider(getIt<MovieRepository>())),
        ChangeNotifierProvider(create: (_) => SearchProvider(getIt<MovieRepository>())),
        ChangeNotifierProvider(create: (_) => WatchlistProvider(getIt<MovieRepository>())),
      ],
      child: Selector<ThemeProvider, ThemeMode>(
        selector: (_, provider) => provider.themeMode,
        builder: (context, themeMode, _) {
          AppColors.isDark = themeMode == ThemeMode.dark;
          return MaterialApp(
            title: 'Cinema',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            themeAnimationDuration: const Duration(milliseconds: 200),
            themeAnimationCurve: Curves.easeOut,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
