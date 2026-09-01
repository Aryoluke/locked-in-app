import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/workout_provider.dart';

class PrScreen extends StatelessWidget {
  const PrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prs = context.watch<WorkoutProvider>().personalRecords;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PERSONAL RECORDS'),
      ),
      body: prs.isEmpty
          ? const Center(
              child: Text(
                'No personal records yet.\nLog heavy completed sets to set PRs.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: prs.length,
              itemBuilder: (context, index) {
                final pr = prs[index];
                final isTop = index == 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isTop ? AppColors.gold : AppColors.surfaceBorder,
                      width: isTop ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: isTop
                              ? AppTheme.goldGradient
                              : const LinearGradient(
                                  colors: [
                                    AppColors.surfaceElevated,
                                    AppColors.surfaceElevated,
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isTop ? Colors.black : AppColors.gold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pr.exerciseName,
                              style: GoogleFonts.rajdhani(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _formatDate(pr.date),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${pr.weight.toStringAsFixed(0)} kg × ${pr.reps}',
                            style: GoogleFonts.rajdhani(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gold,
                            ),
                          ),
                          Text(
                            'e1RM ${pr.estimatedOneRepMax} kg',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
