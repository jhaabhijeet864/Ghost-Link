import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:async';

class AnimatedSplashScreen extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onInit;

  const AnimatedSplashScreen({
    super.key,
    required this.child,
    this.onInit,
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _performInitialization();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  Future<void> _performInitialization() async {
    // Keep native splash visible while initializing
    FlutterNativeSplash.preserve(
      widgetsBinding: WidgetsFlutterBinding.ensureInitialized(),
    );
    try {
      // Run async initialization in parallel with animation
      await Future.wait([
        widget.onInit?.call() ?? Future.value(),
        Future.delayed(const Duration(milliseconds: 2000)), // Min splash duration
      ]);
    } finally {
      // Hide native splash and transition to main app
      FlutterNativeSplash.remove();
      setState(() => _showSplash = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115), // Match native splash color
      body: Stack(
        children: [
          // Main app (hidden until splash completes)
          if (!_showSplash) widget.child,
          // Splash screen with fade-out animation
          if (_showSplash)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Image.asset(
                            'assets/images/localloop_logo.png',
                            width: 200,
                            height: 200,
                          ),
                          const SizedBox(height: 24),
                          // "Local Loop" text
                          const Text(
                            'Local Loop',
                            style: TextStyle(
                              color: Color(0xFFF3F4F6),
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
