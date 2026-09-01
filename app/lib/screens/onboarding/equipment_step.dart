import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';

class EquipmentStep extends StatefulWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback onNext;

  const EquipmentStep({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.onNext,
  });

  @override
  State<EquipmentStep> createState() => _EquipmentStepState();
}

class _EquipmentStepState extends State<EquipmentStep> {
  static const _equipment = [
    ('Gym Access', Icons.apartment),
    ('Barbell', Icons.fitness_center),
    ('Dumbbells', Icons.fitness_center),
    ('Kettlebells', Icons.sports),
    ('Resistance Bands', Icons.cable),
    ('Pull-up Bar', Icons.bar_chart),
    ('Bench', Icons.event_seat),
    ('Cardio Machine', Icons.directions_run),
    ('Home / Bodyweight', Icons.home),
    ('None yet', Icons.block),
  ];

  void _toggle(String item) {
    final updated = List<String>.from(widget.selected);
    if (updated.contains(item)) {
      updated.remove(item);
    } else {
      updated.add(item);
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
            'Step 4 · Equipment',
            style: GoogleFonts.rajdhani(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What do you have?',
            style: GoogleFonts.rajdhani(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This lets us recommend attainable exercises and templates.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: _equipment.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _equipment[index];
                final isSelected = widget.selected.contains(item.$1);
                return InkWell(
                  onTap: () => _toggle(item.$1),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(item.$2,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textMuted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.$1,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: AppColors.primary),
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
