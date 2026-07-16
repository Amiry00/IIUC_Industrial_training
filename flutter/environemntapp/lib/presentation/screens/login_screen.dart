import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../providers/providers.dart';
import '../widgets/common_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    await ref.read(authProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      final authState = ref.read(authProvider);
      if (authState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error.toString(), style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (authState.value != null) {
        context.go('/main');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final textPrimary = isDark ? AppColors.darkPrimaryText : AppColors.primaryText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.mutedText;

    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                const Icon(Icons.eco_rounded, size: 80, color: AppColors.primaryAccent),
                const SizedBox(height: 24),
                Text('Welcome Back', style: AppTypography.heroTitle(textPrimary), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Log in to continue your Air Quality Monitor journey', style: AppTypography.body(mutedText), textAlign: TextAlign.center),
                const SizedBox(height: 48),
                
                TextFormField(
                  controller: _emailController,
                  style: AppTypography.body(textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: AppTypography.label(mutedText),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryAccent),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty || !v.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _passwordController,
                  style: AppTypography.body(textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: AppTypography.label(mutedText),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryAccent),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: mutedText),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 12),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Forgot password feature placeholder
                    },
                    child: Text('Forgot Password?', style: AppTypography.button(AppColors.primaryAccent)),
                  ),
                ),
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: authState.isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Login', style: AppTypography.button(Colors.white).copyWith(fontSize: 16)),
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: AppTypography.body(mutedText)),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: Text('Register', style: AppTypography.button(AppColors.primaryAccent)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
