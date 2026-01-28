import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invispay/routes/app_routes.dart';
import 'package:invispay/services/auth_service.dart';
import 'package:invispay/services/database_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invispay/providers/locale_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Start animation and navigation check
    _controller.forward();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    final auth = AuthService();
    final db = DatabaseService();

    // Minimum splash display time (1.2 seconds)
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    // Check if user has selected language (First Launch)
    final hasSelectedLanguage =
        await ref.read(localeProvider.notifier).hasUserSelectedLanguage();

    if (!hasSelectedLanguage) {
      if (mounted) context.go(AppRoutes.onboardingLanguage);
      return;
    }

    final user = auth.currentUser;

    // Not authenticated -> Login
    if (user == null) {
      if (mounted) context.go(AppRoutes.login);
      return;
    }

    // Authenticated -> Check KYC status
    try {
      final userDoc = await db.getUserStream(user.uid).first;

      if (!userDoc.exists) {
        // No profile, go to login
        if (mounted) context.go(AppRoutes.login);
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>?;
      final kycStatus = data?['kycStatus'] ?? 'pending';

      if (mounted) {
        if (kycStatus == 'verified') {
          context.go(AppRoutes.home);
        } else {
          context.go(AppRoutes.kyc);
        }
      }
    } catch (e) {
      // Error or demo mode -> go to login
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A), // Slate-900
                Color(0xFF1E293B), // Slate-800
              ],
            ),
          ),
          child: Stack(
            children: [
              // Abstract Shapes
              Positioned(
                top: -100,
                right: -100,
                child: _buildAbstractShape(
                    300, const Color(0xFF10B981).withValues(alpha: 0.05)),
              ),
              Positioned(
                bottom: -150,
                left: -50,
                child: _buildAbstractShape(
                    400, const Color(0xFF0D9488).withValues(alpha: 0.03)),
              ),

              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with Glow
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.2),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/invispay_logo.png',
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // App Name
                        Text(
                          'InvisPay',
                          style: GoogleFonts.outfit(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Tagline
                        Text(
                          'The Future of Invisible Payments',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.4),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbstractShape(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
