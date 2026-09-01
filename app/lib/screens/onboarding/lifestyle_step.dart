import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';

class LifestyleStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final void Function(String key, dynamic value) onChanged;
  final VoidCallback onNext;

  const LifestyleStep({
    super.key,
    required this.data,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final activity = data['activity'] as String?;
    final sleep = data['sleep'] as String?;
    final diet = data['diet'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Step 5 · Lifestyle',
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your daily engine',
              style: GoogleFonts.rajdhani(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            _SectionLabel('Activity Level'),
            const SizedBox(height: 8),
            _ChoiceChips(
              options: const [
                ('Sedentary', 'Mostly sitting'),
                ('Light', '1-3 workouts/wk'),
                ('Moderate', '3-5 workouts/wk'),
                ('Very Active', '6-7 workouts/wk'),
              ],
              selected: activity,
              onSelect: (v) => onChanged('activity', v),
            ),
            const SizedBox(height: 24),

            _SectionLabel('Sleep Schedule'),
            const SizedBox(height: 8),
            _ChoiceChips(
              options: const [
                ('Early Bird', '6-8am rise'),
                ('Night Owl', '11pm+ sleep'),
                ('Flexible', 'Unpredictable'),
              ],
              selected: sleep,
              onSelect: (v) => onChanged('sleep', v),
            ),
            const SizedBox(height: 24),

            _SectionLabel('Dietary Preference'),
            const SizedBox(height: 8),
            _ChoiceChips(
              options: const [
                ('Standard', 'Eat everything'),
                ('Vegetarian', 'No meat'),
                ('Vegan', 'Plant-based'),
                ('Keto', 'Low carb'),
                ('Flexible', 'Whatever fits'),
              ],
              selected: diet,
              onSelect: (v) => onChanged('diet', v),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (activity == null || sleep == null || diet == null)
                        ? null
                        : onNext,
                child: const Text('CONTINUE'),
              ),
            ),
            const SizedBox(height: 24),
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

class _ChoiceChips extends StatelessWidget {
  final List<(String, String)> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _ChoiceChips({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, desc) in options)
          InkWell(
            onTap: () => onSelect(value),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected == value
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected == value
                      ? AppColors.primary
                      : AppColors.surfaceBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected == value
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
