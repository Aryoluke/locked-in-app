import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../config/theme.dart';

class XpBar extends StatelessWidget {
  final int level;
  final int totalXp;
  final double progress; // 0..1
  final int xpToNext;

  const XpBar({
    super.key,
    required this.level,
    required this.totalXp,
    required this.progress,
    required this.xpToNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gold, AppColors.goldDark],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '$level',
              style: GoogleFonts.rajdhani(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                duration: 2.seconds,
                begin: Offset(1, 1),
                end: Offset(1.03, 1.03),
                curve: Curves.easeInOut,
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Level $level',
                      style: GoogleFonts.rajdhani(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$totalXp XP',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearPercentIndicator(
                    percent: progress.clamp(0.0, 1.0),
                    lineHeight: 10,
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.surfaceElevated,
                    progressColor: AppColors.primary,
                    animation: true,
                    animationDuration: 800,
                    barRadius: const Radius.circular(20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$xpToNext XP to next level',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
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
