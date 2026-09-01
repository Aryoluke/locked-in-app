import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';

/// Shared scaffolding for all onboarding steps.
class OnboardingStepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onNext;
  final List<Widget> children;

  const OnboardingStepScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    this.onNext,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.rajdhani(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ...children,
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onNext,
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );
  }
}
