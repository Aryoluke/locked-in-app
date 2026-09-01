import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/xp_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final xp = context.watch<XpProvider>();
    final workouts = context.watch<WorkoutProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PROFILE'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.darkGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.surfaceElevated,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? 'LOCKED IN Athlete',
                  style: GoogleFonts.rajdhani(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Level ${xp.level} · ${xp.totalXp} XP',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (user?.lockInLevel ?? 'Asleep').toUpperCase(),
                    style: GoogleFonts.rajdhani(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats grid
          Row(
            children: [
              _StatTile(
                icon: Icons.fitness_center,
                value: '${workouts.history.length}',
                label: 'Workouts',
              ),
              const SizedBox(width: 10),
              _StatTile(
                icon: Icons.bolt,
                value: '${xp.totalXp}',
                label: 'Total XP',
              ),
              const SizedBox(width: 10),
              _StatTile(
                icon: Icons.local_fire_department,
                value: '${user?.currentStreak ?? 0}',
                label: 'Streak',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Profile details
          _SectionLabel('DETAILS'),
          const SizedBox(height: 8),
          _DetailRow('Body Type',
              user?.bodyType ?? 'Not set', Icons.person_outline),
          _DetailRow('Height',
              user?.heightCm != null ? '${user!.heightCm!.toStringAsFixed(0)} cm' : 'Not set',
              Icons.height),
          _DetailRow('Weight',
              user?.weightKg != null ? '${user!.weightKg!.toStringAsFixed(0)} kg' : 'Not set',
              Icons.monitor_weight_outlined),
          _DetailRow('Fitness Goal',
              user?.fitnessGoal ?? 'Not set', Icons.flag),
          _DetailRow('Activity',
              user?.activityLevel ?? 'Not set', Icons.directions_run),
          _DetailRow('Diet',
              user?.dietaryPreference ?? 'Not set', Icons.restaurant),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.rajdhani(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.rajdhani(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
