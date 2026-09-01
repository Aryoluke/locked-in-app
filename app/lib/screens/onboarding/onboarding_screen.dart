import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import 'body_type_step.dart';
import 'profile_step.dart';
import 'goals_step.dart';
import 'equipment_step.dart';
import 'lifestyle_step.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentStep = 0;
  final int _totalSteps = 6;

  // Collected data across steps
  String? _bodyType;
  final _profileData = <String, dynamic>{};
  final _goals = <String>[];
  final _equipment = <String>[];
  final _lifestyle = <String, dynamic>{};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _finish() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final existing = auth.user;

    if (existing != null) {
      final updated = existing.copyWith(
        bodyType: _bodyType,
        heightCm: (_profileData['height'] as num?)?.toDouble(),
        weightKg: (_profileData['weight'] as num?)?.toDouble(),
        dateOfBirth: _profileData['dob'] as DateTime?,
        goals: _goals,
        availableEquipment: _equipment,
        activityLevel: _lifestyle['activity'] as String?,
        sleepSchedule: _lifestyle['sleep'] as String?,
        dietaryPreference: _lifestyle['diet'] as String?,
        onboardingComplete: true,
      );
      await auth.completeOnboarding(updated);
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _back,
                    child: Icon(
                      _currentStep == 0 ? Icons.close : Icons.arrow_back,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / _totalSteps,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_currentStep + 1}/$_totalSteps',
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  BodyTypeStep(
                    selected: _bodyType,
                    onChanged: (v) => _bodyType = v,
                    onNext: _next,
                  ),
                  ProfileStep(
                    data: _profileData,
                    onChanged: (k, v) => _profileData[k] = v,
                    onNext: _next,
                  ),
                  GoalsStep(
                    selected: _goals,
                    onChanged: (goals) => _goals
                      ..clear()
                      ..addAll(goals),
                    onNext: _next,
                  ),
                  EquipmentStep(
                    selected: _equipment,
                    onChanged: (eq) => _equipment
                      ..clear()
                      ..addAll(eq),
                    onNext: _next,
                  ),
                  LifestyleStep(
                    data: _lifestyle,
                    onChanged: (k, v) => _lifestyle[k] = v,
                    onNext: _next,
                  ),
                  _CompleteStep(onFinish: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompleteStep extends StatelessWidget {
  final VoidCallback onFinish;

  const _CompleteStep({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.neonGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonGreen.withOpacity(0.4),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const Icon(Icons.check, size: 56, color: Colors.black),
          )
              .animate()
              .scale(begin: Offset(0.4, 0.4), end: Offset(1, 1),
                  curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Text(
            'YOU\'RE READY',
            style: GoogleFonts.rajdhani(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your profile is set up. Time to start your streak,\nlog your first workout, and LOCK IN.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onFinish,
              child: const Text('ENTER LOCKED IN'),
            ),
          ),
        ],
      ),
    );
  }
}
