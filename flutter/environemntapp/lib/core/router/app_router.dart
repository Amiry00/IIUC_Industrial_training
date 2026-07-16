import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/main_shell.dart';
import '../../presentation/screens/detail_screen.dart';

import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/register_screen.dart';
import '../../presentation/screens/notification_screen.dart';
import '../../presentation/screens/settings_screen.dart';

/// Application router configuration using go_router.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/main', builder: (_, __) => const MainShell()),
      GoRoute(path: '/detail/:id', builder: (_, state) => DetailScreen(stationId: state.pathParameters['id']!)),

    ],
  );
}
