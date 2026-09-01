import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/daily_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/social_provider.dart';
import '../../providers/study_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/xp_provider.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/streak_flame.dart';
import '../../widgets/xp_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final daily = context.watch<DailyProvider>();
    final xp = context.watch<XpProvider>();
    final workouts = context.watch<WorkoutProvider>();
    final social = context.watch<SocialProvider>();

    final streak = auth.user?.currentStreak ?? 0;
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.lock, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text('LOCKED IN'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () =>
          Provider.of<SyncProvider>(context, listen: false).syncNow(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const OfflineIndicator(),

            // ===== Top stats row =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _todayLabel(),
                          style: GoogleFonts.rajdhani(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.displayName ?? 'Welcome back',
                          style: GoogleFonts.rajdhani(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Streak flame
                  StreakFlame(count: streak, size: 44),
                  const SizedBox(width: 8),
                  // Lock-in level badge
                  _LockInBadge(level: auth.user?.lockInLevel ?? 'Asleep'),
                ],
              ),
            ),

            // ===== XP bar =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: XpBar(
                level: xp.level,
                totalXp: xp.totalXp,
                progress: xp.progressToNext,
                xpToNext: xp.xpForNextLevel - xp.xpForCurrentLevel,
              ),
            ),

            const SizedBox(height: 16),

            // ===== Today's plan =====
            _SectionTitle('Today\'s Plan'),
            _TodayPlanCard(
              workoutActive: workouts.activeWorkout != null,
              workoutCount: workouts.activeSets.length,
              habitsDue: _habitsDue(context),
              studyMinutes: 0,
            ),

            const SizedBox(height: 16),

            // ===== Recovery status =====
            _SectionTitle('Recovery'),
            _RecoveryCard(
              sleepQuality: daily.today?.sleepQuality ?? 3,
              soreness: daily.today?.muscleSoreness ?? 1,
              energy: daily.today?.energyLevel ?? 3,
              status: daily.today?.recoveryStatus ?? 'Good',
            ),

            const SizedBox(height: 16),

            // ===== Water tracker =====
            _SectionTitle('Hydration'),
            _WaterTracker(
              liters: daily.today?.waterLiters ?? 0,
              goal: AppConstants.waterGoalLiters,
              onTap: () async {
                final dp = Provider.of<DailyProvider>(context, listen: false);
                await dp.logWater();
              },
            ),

            const SizedBox(height: 16),

            // ===== Quick actions =====
            _SectionTitle('Quick Actions'),
            _QuickActions(onAction: (action) {
              switch (action) {
                case 'workout':
                  Navigator.pushNamed(context, AppRoutes.workoutLog);
                case 'water':
                  Provider.of<DailyProvider>(context, listen: false).logWater();
                case 'study':
                  Navigator.pushNamed(context, AppRoutes.study);
                case 'voice':
                  _showVoiceLogDialog(context);
              }
            }),

            const SizedBox(height: 16),

            // ===== Squad activity =====
            _SectionTitle('Squad Activity'),
            _SquadFeed(events: social.activity.take(5).toList()),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[now.weekday - 1]} · ${now.day} ${months[now.month - 1]}';
  }

  int _habitsDue(BuildContext context) {
    final habits = context.watch<HabitProvider>();
    return habits.habits.where((h) => !habits.isCompletedToday(h)).length;
  }

  void _showVoiceLogDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic, size: 40, color: AppColors.primary),
            const SizedBox(height: 12),
            const Text(
              'Voice Log',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Voice logging requires a device that supports speech-to-text.\nHold to record your day.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('NOT AVAILABLE YET'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.rajdhani(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockInBadge extends StatelessWidget {
  final String level;
  const _LockInBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppTheme.goldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            level.toUpperCase(),
            style: GoogleFonts.rajdhani(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            'LOCK-IN LEVEL',
            style: TextStyle(
              fontSize: 8,
              color: Colors.black.withOpacity(0.7),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayPlanCard extends StatelessWidget {
  final bool workoutActive;
  final int workoutCount;
  final int habitsDue;
  final int studyMinutes;

  const _TodayPlanCard({
    required this.workoutActive,
    required this.workoutCount,
    required this.habitsDue,
    required this.studyMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (workoutActive)
            Row(
              children: [
                const Icon(Icons.fitness_center, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Workout in progress ($workoutCount sets logged)',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ).animate().fadeIn(),
          const SizedBox(height: 8),
          Row(
            children: [
              _planItem(context, Icons.check_circle_outline,
                  habitsDue == 0 ? 'All habits done!' : '$habitsDue habits due',
                  habitsDue == 0 ? AppColors.success : AppColors.warning),
              const SizedBox(width: 16),
              _planItem(context, Icons.school_outlined,
                  studyMinutes > 0 ? 'Study logged' : 'Study: none yet',
                  AppColors.mindColor),
              const SizedBox(width: 16),
              _planItem(context, Icons.local_fire_department,
                  workoutActive ? 'Active' : 'No workout yet',
                  AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _planItem(BuildContext context, IconData icon, String text, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            text,
            maxLines: 2,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final int sleepQuality;
  final int soreness;
  final int energy;
  final String status;

  const _RecoveryCard({
    required this.sleepQuality,
    required this.soreness,
    required this.energy,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = status == 'Primed'
        ? AppColors.success
        : status == 'Good'
            ? AppColors.primary
            : status == 'Tired'
                ? AppColors.warning
                : AppColors.error;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          // Status ring
          SizedBox(
            width: 64,
            height: 64,
            child: CircularPercentIndicator(
              radius: 30,
              percent: _recoveryPercent().clamp(0.0, 1.0),
              lineWidth: 6,
              backgroundColor: AppColors.surfaceElevated,
              progressColor: color,
              center: Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _recLabel(Icons.bedtime, 'Sleep', '$sleepQuality/5'),
                _recLabel(Icons.healing, 'Recovery', _sorenessLabel()),
                _recLabel(Icons.bolt, 'Energy', '$energy/5'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _recoveryPercent() {
    final score = (sleepQuality * 2 + (6 - soreness) + energy) / 12;
    return score;
  }

  String _sorenessLabel() {
    if (soreness <= 1) return 'Fresh';
    if (soreness <= 2) return 'Slight';
    if (soreness <= 3) return 'Moderate';
    return 'Sore';
  }

  Widget _recLabel(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterTracker extends StatelessWidget {
  final double liters;
  final double goal;
  final VoidCallback onTap;

  const _WaterTracker({
    required this.liters,
    required this.goal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (liters / goal).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CircularPercentIndicator(
              radius: 34,
              percent: percent,
              lineWidth: 8,
              backgroundColor: AppColors.surfaceElevated,
              progressColor: const Color(0xFF3B82F6),
              center: Icon(
                Icons.water_drop,
                color: percent >= 1
                    ? AppColors.success
                    : const Color(0xFF3B82F6),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${liters.toStringAsFixed(1)}L / ${goal.toStringAsFixed(0)}L',
                  style: GoogleFonts.rajdhani(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  percent >= 1
                      ? 'Goal hit! Keep sipping.'
                      : '${((1 - percent) * goal).toStringAsFixed(1)}L to go',
                  style: TextStyle(
                    fontSize: 12,
                    color: percent >= 1
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final ValueChanged<String> onAction;

  const _QuickActions({required this.onAction});

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Log Workout', Icons.fitness_center, AppColors.primary, 'workout'),
      ('Log Water', Icons.water_drop, const Color(0xFF3B82F6), 'water'),
      ('Start Study', Icons.school, AppColors.mindColor, 'study'),
      ('Voice Log', Icons.mic, AppColors.gold, 'voice'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => onAction(actions[i].$4),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    children: [
                      Icon(actions[i].$2, color: actions[i].$3, size: 24),
                      const SizedBox(height: 6),
                      Text(
                        actions[i].$1,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SquadFeed extends StatelessWidget {
  final List<dynamic> events;

  const _SquadFeed({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: const Column(
          children: [
            Icon(Icons.groups, color: AppColors.textMuted, size: 32),
            SizedBox(height: 8),
            Text(
              'No squad activity yet.\nYour feed will light up when your crew logs in.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final event = events[index];
          final userName = event.userName ?? 'Squad member';
          final message = event.message ?? '';
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: AppColors.surfaceElevated,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(
              userName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: event.xpEarned != null && event.xpEarned > 0
                ? Text(
                    '+${event.xpEarned}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }
}
