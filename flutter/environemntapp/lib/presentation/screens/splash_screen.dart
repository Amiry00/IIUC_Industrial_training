import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _minSplashTimeElapsed = false;

  @override
  void initState() {
    super.initState();
    // Increased duration to 2500ms to allow text animations (which take up to 1500ms) to finish displaying
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _minSplashTimeElapsed = true);
        _checkAuthAndNavigate();
      }
    });
  }

  void _checkAuthAndNavigate() {
    if (!_minSplashTimeElapsed) return;
    
    final authState = ref.read(authProvider);
    if (!authState.isLoading) {
      if (authState.value != null) {
        context.go('/main');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      _checkAuthAndNavigate();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkPrimaryBackground : AppColors.primaryBackground;
    final accent = isDark ? AppColors.darkPrimaryAccent : AppColors.primaryAccent;
    final textPrimary = isDark ? AppColors.darkPrimaryText : AppColors.primaryText;
    final textSecondary = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.eco_rounded, size: 64, color: Colors.white),
            )
                .animate()
                .scale(duration: 800.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 600.ms),
            const SizedBox(height: 32),
            Text('Air Quality Monitor', style: AppTypography.heroTitle(textPrimary))
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text('Live Green, Live Clean', style: AppTypography.body(textSecondary))
                .animate()
                .fadeIn(delay: 700.ms, duration: 600.ms),
            const SizedBox(height: 48),
            SizedBox(
              width: 32, height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: accent),
            ).animate().fadeIn(delay: 1000.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
