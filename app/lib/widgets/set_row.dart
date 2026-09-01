import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';
import '../models/workout.dart';

class SetRow extends StatelessWidget {
  final WorkoutSet set;
  final VoidCallback? onToggleComplete;
  final ValueChanged<int>? onRepsChanged;
  final ValueChanged<double>? onWeightChanged;
  final ValueChanged<String>? onNotesChanged;

  const SetRow({
    super.key,
    required this.set,
    this.onToggleComplete,
    this.onRepsChanged,
    this.onWeightChanged,
    this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: set.completed
            ? AppColors.primary.withOpacity(0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: set.completed
              ? AppColors.primary.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 40,
            child: Text(
              '#${set.setNumber}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          // Reps
          Expanded(
            child: _EditableNumber(
              value: set.reps,
              suffix: 'reps',
              onChanged: (v) => onRepsChanged?.call(v),
            ),
          ),
          const SizedBox(width: 8),
          // Weight
          Expanded(
            child: _EditableNumber(
              value: set.weight.round(),
              suffix: 'kg',
              onChanged: (v) => onWeightChanged?.call(v.toDouble()),
            ),
          ),
          // Complete toggle
          InkWell(
            onTap: onToggleComplete,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: set.completed ? AppColors.primary : AppColors.surfaceElevated,
                border: Border.all(
                  color: set.completed ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              child: Icon(
                set.completed ? Icons.check : Icons.radio_button_unchecked,
                size: 18,
                color: set.completed ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableNumber extends StatelessWidget {
  final int value;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _EditableNumber({
    required this.value,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _showEditor(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: value == 0 ? AppColors.textMuted : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            suffix,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  void _showEditor(BuildContext context) {
    final controller = TextEditingController(text: '$value');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Enter $suffix'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(fontSize: 20, color: AppColors.textPrimary),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(controller.text) ?? 0;
              onChanged(v);
              Navigator.pop(dialogContext);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
