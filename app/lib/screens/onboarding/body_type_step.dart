import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';

class BodyTypeStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  const BodyTypeStep({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Step 1 · Body Type',
            style: GoogleFonts.rajdhani(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What are you building?',
            style: GoogleFonts.rajdhani(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose the physique you\'re working toward. This tunes your default training focus.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          _BodyTypeOption(
            title: 'SLEEPER',
            subtitle: 'Lean & athletic · build muscle while staying sharp',
            icon: Icons.directions_run,
            color: AppColors.primary,
            selected: selected == 'sleeper',
            onTap: () => onChanged('sleeper'),
          ),
          const SizedBox(height: 12),
          _BodyTypeOption(
            title: 'BULK',
            subtitle: 'Raw size & strength · pack on mass',
            icon: Icons.fitness_center,
            color: AppColors.warning,
            selected: selected == 'bulk',
            onTap: () => onChanged('bulk'),
          ),
          const SizedBox(height: 12),
          _BodyTypeOption(
            title: 'HYBRID',
            subtitle: 'The all-rounder · strength + conditioning + looks',
            icon: Icons.all_inclusive,
            color: AppColors.gold,
            selected: selected == 'hybrid',
            onTap: () => onChanged('hybrid'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selected == null ? null : onNext,
              child: const Text('CONTINUE'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _BodyTypeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _BodyTypeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppColors.surfaceBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.rajdhani(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: selected ? color : AppColors.textPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}
