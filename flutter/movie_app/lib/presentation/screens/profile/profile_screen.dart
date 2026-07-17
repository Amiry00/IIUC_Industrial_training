import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinema/core/constants/app_constants.dart';
import 'package:cinema/providers/theme_provider.dart';
import 'package:cinema/data/repository/movie_repository.dart';
import 'package:cinema/providers/auth_provider.dart';
import 'package:cinema/providers/watchlist_provider.dart';
import 'package:cinema/presentation/screens/profile/login_screen.dart';
import 'package:get_it/get_it.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          children: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final user = auth.currentUser;
              return Column(
                children: [
                  const SizedBox(height: 16),
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Theme.of(context).cardColor,
                      child: Icon(Icons.person_rounded, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (user != null) ...[
                    Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(user.email, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
                  ] else ...[
                    Text('Guest', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text('Login or Register', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              );
            },
          ),

            // Dark mode toggle
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: Icon(Icons.dark_mode_outlined, color: Theme.of(context).colorScheme.onSurface),
                      title: Text('Dark Mode', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Clear cache
            _buildSettingItem(context, Icons.delete_outline_rounded, 'Clear Cache', onTap: () async {
              await GetIt.I<MovieRepository>().clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cache cleared'), backgroundColor: Theme.of(context).cardColor,
                    behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                );
              }
            }),

            _buildSettingItem(context, Icons.info_outline_rounded, 'About Cinema', onTap: () {
              showAboutDialog(
                context: context,
                applicationName: AppStrings.appName,
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 Cinema\nPowered by TMDb API',
              );
            }),

            const SizedBox(height: 8),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (!auth.isAuthenticated) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: Icon(Icons.logout_rounded, color: Theme.of(context).colorScheme.error),
                      title: Text('Log Out', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16)),
                      onTap: () async {
                        await auth.logout();
                        if (context.mounted) {
                          context.read<WatchlistProvider>().loadWatchlist();
                        }
                      },
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
            Text('Powered by TMDb API', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
            const SizedBox(height: 4),
            Text('Cinema v1.0.0', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
          title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
          trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          onTap: onTap,
        ),
      ),
    );
  }
}
