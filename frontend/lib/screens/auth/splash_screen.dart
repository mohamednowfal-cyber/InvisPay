import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:invispay/routes/app_routes.dart';
import 'package:invispay/services/auth_service.dart';
import 'package:invispay/services/database_service.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invispay/providers/locale_provider.dart';
import 'package:firebase_core/firebase_core.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _fadeController;
  late AnimationController _zoomController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _zoomAnimation;
  bool _initialized = false;
  bool _isNavigating = false;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();

    // Setup fade transition for seamless screen exit
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Setup cinematic entrance zoom (gently push-in)
    _zoomController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000));
    _zoomAnimation = Tween<double>(begin: 1.15, end: 1.25).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.linear),
    );

    // Parallel initialization: Video and App Engine
    _initializeVideo();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase background init warning: $e');
    }
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset(
      'assets/animations/splash_animation.mp4',
    );

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _initialized = true;
          _isVideoReady = true;
        });
        _controller.play();
        _controller.addListener(_videoListener);
        _zoomController.forward();
      }
    } catch (e) {
      debugPrint('Error initializing splash video: $e');
      _navigateToNextScreen();
    }
  }

  void _videoListener() {
    if (!mounted || _isNavigating) return;

    final position = _controller.value.position;
    final duration = _controller.value.duration;

    if (position >= duration - const Duration(milliseconds: 300)) {
      _controller.removeListener(_videoListener);
      _fadeOutAndNavigate();
    }
  }

  Future<void> _fadeOutAndNavigate() async {
    if (_isNavigating) return;
    _isNavigating = true;

    await _fadeController.forward();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    final auth = AuthService();
    final db = DatabaseService();

    if (!mounted) return;

    final hasSelectedLanguage =
        await ref.read(localeProvider.notifier).hasUserSelectedLanguage();

    if (!hasSelectedLanguage) {
      if (mounted) context.go(AppRoutes.onboardingLanguage);
      return;
    }

    final user = auth.currentUser;

    if (user == null) {
      if (mounted) context.go(AppRoutes.login);
      return;
    }

    try {
      final userDoc = await db.getUserStream(user.uid).first;

      if (!userDoc.exists) {
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
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _fadeController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF091a35),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF041633),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF041633),
                Color(0xFF091a35),
              ],
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: _initialized && _isVideoReady
                  ? ScaleTransition(
                      scale: _zoomAnimation,
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
