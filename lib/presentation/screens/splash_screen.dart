import 'package:flutter/material.dart';

import '../../core/constants/branding.dart';
import '../../core/theme/app_theme.dart';
import '../controllers/investigation_controller.dart';
import 'dashboard_screen.dart';

/// Pantalla Splash animada y responsiva con duración configurable (por defecto 2.6s).
class SplashScreen extends StatefulWidget {
  final InvestigationController controller;
  final Duration minDuration;
  final VoidCallback? onTransition;

  const SplashScreen({
    super.key,
    required this.controller,
    this.minDuration = const Duration(milliseconds: 2600),
    this.onTransition,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: widget.minDuration > Duration.zero
          ? widget.minDuration
          : const Duration(milliseconds: 100),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOut,
      ),
    );

    _animController.forward();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    await Future.wait([
      widget.controller.loadSettings(),
      widget.controller.load(),
    ]);

    if (widget.minDuration > Duration.zero) {
      await Future<void>.delayed(widget.minDuration);
    }

    if (!mounted) return;

    if (widget.onTransition != null) {
      widget.onTransition!();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => DashboardScreen(controller: widget.controller),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Isotipo animado de LUKZINT
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceAlt,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.shield_outlined,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Título y Branding
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                AppBranding.appName,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2.0,
                                      color: AppColors.text,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'v${AppBranding.appVersion}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppBranding.tagline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Indicador de carga animado finito (determinado por el controlador)
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, _) {
                        return SizedBox(
                          width: 140,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _progressAnimation.value,
                              minHeight: 3,
                              backgroundColor: AppColors.surfaceAlt,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(),

                    // Watermark footer
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          AppBranding.watermark,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
