import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/daily_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/social_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/study_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/xp_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.init();

    // Initialize providers in parallel once authenticated
    if (auth.isAuthenticated) {
      await Future.wait([
        Provider.of<WorkoutProvider>(context, listen: false).init(),
        Provider.of<HabitProvider>(context, listen: false).init(),
        Provider.of<DailyProvider>(context, listen: false).init(),
        Provider.of<StreakProvider>(context, listen: false).init(),
        Provider.of<XpProvider>(context, listen: false).init(),
        Provider.of<StudyProvider>(context, listen: false).init(),
        Provider.of<SocialProvider>(context, listen: false).init(),
      ]);
      await Provider.of<SyncProvider>(context, listen: false).init();
    }

    if (!mounted) return;

    // Small delay to let the logo animation breathe
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    if (!auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else if (!auth.hasCompletedOnboarding) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock icon + flame
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock,
                size: 56,
                color: Colors.white,
              ),
            )
                .animate(controller: _controller)
                .scale(
                  begin: Offset(0.5, 0.5),
                  end: Offset(1, 1),
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 28),
            Text(
              'LOCKED IN',
              style: GoogleFonts.rajdhani(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.textPrimary,
              ),
            )
                .animate(controller: _controller)
                .fadeIn(begin: 0, delay: 300.ms)
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),
            Text(
              'FITNESS · MIND · LIFE · SQUAD',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 3,
                color: AppColors.gold,
              ),
            )
                .animate(controller: _controller)
                .fadeIn(begin: 0, delay: 500.ms),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ).animate(controller: _controller).fadeIn(delay: 700.ms),
          ],
        ),
      ),
    );
  }
}
