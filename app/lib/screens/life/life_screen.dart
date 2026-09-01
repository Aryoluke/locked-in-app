import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/daily_provider.dart';
import '../../providers/habit_provider.dart';

class LifeScreen extends StatelessWidget {
  const LifeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('LIFE'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Habits'),
              Tab(text: 'Daily Care'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _HabitsTab(),
            _DailyCareTab(),
          ],
        ),
      ),
    );
  }
}

class _HabitsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>();
    final daily = context.watch<DailyProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Habits progress ring
        Container(
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
                  percent: habits.todayProgress,
                  lineWidth: 8,
                  backgroundColor: AppColors.surfaceElevated,
                  progressColor: AppColors.primary,
                  center: Text(
                    '${(habits.todayProgress * 100).round()}%',
                    style: GoogleFonts.rajdhani(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${habits.habits.where((h) => habits.isCompletedToday(h)).length}/${habits.habits.length} habits done',
                      style: GoogleFonts.rajdhani(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Keep the chain alive to level up your lock-in.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.habits),
          icon: const Icon(Icons.add),
          label: const Text('MANAGE HABITS'),
        ),
        const SizedBox(height: 8),
        if (habits.habits.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No habits yet.\nAdd daily habits to start building discipline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...habits.habits.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _HabitSummaryTile(habit: h, completed: habits.isCompletedToday(h)),
              )),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _HabitSummaryTile extends StatelessWidget {
  final dynamic habit;
  final bool completed;

  const _HabitSummaryTile({required this.habit, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed ? AppColors.primary : AppColors.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? AppColors.primary : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Text(habit.icon ?? '✅', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              habit.name ?? '',
              style: TextStyle(
                color: completed ? AppColors.textMuted : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyCareTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final daily = context.watch<DailyProvider>();
    final water = daily.today?.waterLiters ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionLabel('WATER'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              // Bottle visualization
              SizedBox(
                width: 40,
                height: 80,
                child: CustomPaint(
                  painter: _BottlePainter(
                    progress: (water / AppConstants.waterGoalLiters).clamp(0.0, 1.0),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${water.toStringAsFixed(1)}L / ${AppConstants.waterGoalLiters.toStringAsFixed(0)}L',
                      style: GoogleFonts.rajdhani(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(water / 0.25).round()} glasses',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Provider.of<DailyProvider>(context, listen: false).logWater();
                },
                icon: const Icon(Icons.add_circle,
                    color: AppColors.primary, size: 32),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _SectionLabel('SLEEP'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: _SleepTracker(
            hours: daily.today?.sleepHours ?? 0,
            quality: daily.today?.sleepQuality ?? 3,
          ),
        ),
        const SizedBox(height: 20),

        _SectionLabel('DAILY CARE'),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.skin),
          icon: const Icon(Icons.face_retouching_natural),
          label: const Text('SKINCARE & GROOMING ROUTINE'),
        ),
      ],
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

class _SleepTracker extends StatelessWidget {
  final int hours;
  final int quality;
  const _SleepTracker({required this.hours, required this.quality});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: hours == 0 ? null : hours,
                decoration: const InputDecoration(labelText: 'Hours slept'),
                items: [
                  for (var i = 0; i <= 12; i++)
                    DropdownMenuItem(value: i, child: Text('$i hours')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    Provider.of<DailyProvider>(context, listen: false)
                        .logSleep(v, quality);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: quality,
                decoration: const InputDecoration(labelText: 'Quality'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Poor')),
                  DropdownMenuItem(value: 2, child: Text('Fair')),
                  DropdownMenuItem(value: 3, child: Text('Good')),
                  DropdownMenuItem(value: 4, child: Text('Great')),
                  DropdownMenuItem(value: 5, child: Text('Excellent')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    Provider.of<DailyProvider>(context, listen: false)
                        .logSleep(hours, v);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BottlePainter extends CustomPainter {
  final double progress;
  _BottlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bottleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 4, w, h - 8),
      const Radius.circular(8),
    );
    final bg = Paint()
      ..color = AppColors.surfaceElevated
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bottleRect, bg);

    // Water fill from bottom
    final fillHeight = (h - 8) * progress;
    if (fillHeight > 0) {
      final waterRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h - 4 - fillHeight, w, fillHeight),
        const Radius.circular(8),
      );
      final water = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
        ).createShader(waterRect.outerRect)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(waterRect, water);
    }

    // Neck
    final neck = Paint()
      ..color = AppColors.surfaceElevated
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.3, 0, w * 0.4, 6),
        const Radius.circular(2),
      ),
      neck,
    );
  }

  @override
  bool shouldRepaint(covariant _BottlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
