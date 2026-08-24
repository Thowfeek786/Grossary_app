import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';

class DealerSplashScreen extends StatefulWidget {
  const DealerSplashScreen({super.key});

  @override
  State<DealerSplashScreen> createState() => _DealerSplashScreenState();
}

class _DealerSplashScreenState extends State<DealerSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _textController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _pulseScale;
  late Animation<Offset> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    // Logo entrance animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Infinite logo pulsing background glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Text slide & fade animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start sequence
    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    await _logoController.forward();
    await _textController.forward();

    if (!mounted) return;
    final auth = context.read<DealerAuthProvider>();

    // Wait until Firebase Auth resolves status from unknown
    while (auth.status == AuthStatus.unknown) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (auth.status == AuthStatus.authenticated) {
      context.go('/dashboard');
    } else {
      final hasSeen = await OnboardingService.hasSeenOnboarding('dealer');
      if (mounted) {
        context.go(hasSeen ? '/login' : '/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Dynamic Onyx & Emerald Gradient Background
          Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF050505),
                  Color(0xFF0D2416),
                  Color(0xFF0A0A0A),
                ],
              ),
            ),
          ),

          // Decorative Floating Glowing Orbs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E).withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -70,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF15803D).withValues(alpha: 0.08),
              ),
            ),
          ),

          // Main Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Stack layout for Pulsing Aura + Centered Logo
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated Pulsing Aura Ring
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseScale.value,
                            child: Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4ADE80).withValues(alpha: 0.35),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Scale & Fade Partner Logo Card
                      ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoOpacity,
                          child: Container(
                            width: 155,
                            height: 155,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121212),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/logos/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.storefront_rounded,
                                  size: 70,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Animated Text Effects: Title & Tagline
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        // Shimmer Text Sweep Effect for "GroceryGo Partner"
                        Shimmer.fromColors(
                          baseColor: Colors.white,
                          highlightColor: const Color(0xFF86EFAC),
                          period: const Duration(milliseconds: 2200),
                          child: const Text(
                            'GroceryGo Partner',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Fade & Slide Animated Tagline Badge
                        FadeTransition(
                          opacity: _taglineOpacity,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1C),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.handshake_rounded,
                                  color: Color(0xFF4ADE80),
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'GROW YOUR GROCERY BUSINESS',
                                  style: TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Bottom Progress Bar Loader
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4ADE80),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
