import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';

class GoalsStep extends StatefulWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback onNext;

  const GoalsStep({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.onNext,
  });

  @override
  State<GoalsStep> createState() => _GoalsStepState();
}

class _GoalsStepState extends State<GoalsStep> {
  static const _goals = [
    ('Build Muscle', 'Hypertrophy & strength', Icons.fitness_center, AppColors.primary),
    ('Lose Fat', 'Cut & lean down', Icons.local_fire_department, AppColors.error),
    ('Get Stronger', 'Compound lifts & PRs', Icons.emoji_events, AppColors.gold),
    ('Improve Cardio', 'Endurance & conditioning', Icons.directions_run, AppColors.info),
    ('Improve Focus', 'Study & deep work', Icons.psychology, AppColors.mindColor),
    ('Build Habits', 'Discipline & consistency', Icons.calendar_month, AppColors.warning),
    ('Boost Confidence', 'Mindset & self-image', Icons.self_improvement, AppColors.lifeColor),
    ('Join the Squad', 'Competition & accountability', Icons.groups, AppColors.squadColor),
  ];

  void _toggle(String goal) {
    final updated = List<String>.from(widget.selected);
    if (updated.contains(goal)) {
      updated.remove(goal);
    } else {
      updated.add(goal);
    }
    setState(() => widget.onChanged(updated));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Step 3 · Goals',
            style: GoogleFonts.rajdhani(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What are you chasing?',
            style: GoogleFonts.rajdhani(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select all that apply. Your dashboard adapts to your goals.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                final isSelected = widget.selected.contains(goal.$1);
                return InkWell(
                  onTap: () => _toggle(goal.$1),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? goal.$4.withOpacity(0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? goal.$4 : AppColors.surfaceBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(goal.$3,
                            color: isSelected ? goal.$4 : AppColors.textMuted,
                            size: 30),
                        const SizedBox(height: 8),
                        Text(
                          goal.$1,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.rajdhani(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? goal.$4
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          goal.$2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.selected.isEmpty ? null : widget.onNext,
              child: Text(
                'CONTINUE (${widget.selected.length} selected)',
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
