import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../models/habit.dart';

class HabitTile extends StatefulWidget {
  final Habit habit;
  final bool completedToday;
  final int todayCount;
  final void Function(Habit) onToggle;
  final void Function(Habit)? onDelete;

  const HabitTile({
    super.key,
    required this.habit,
    required this.completedToday,
    required this.todayCount,
    required this.onToggle,
    this.onDelete,
  });

  @override
  State<HabitTile> createState() => _HabitTileState();
}

class _HabitTileState extends State<HabitTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.completedToday;

    return Dismissible(
      key: Key(widget.habit.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        widget.onDelete?.call(widget.habit);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _popController.forward(from: 0);
            widget.onToggle(widget.habit);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: completed ? AppColors.primary : AppColors.surfaceBorder,
                width: completed ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Completion checkbox
                _buildCheckbox(completed),
                const SizedBox(width: 12),
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.habit.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + streak
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habit.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: completed
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: widget.habit.currentStreak >= 7
                                ? AppColors.gold
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${widget.habit.currentStreak} day streak',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Today's count
                if (widget.habit.targetCount > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${widget.todayCount}/${widget.habit.targetCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate(controller: _popController).scale(
          duration: 250.ms,
          begin: Offset(0.85, 0.85),
          end: Offset(1.0, 1.0),
          curve: Curves.elasticOut,
        );
  }

  Widget _buildCheckbox(bool completed) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.elasticOut,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: completed ? AppColors.primary : AppColors.textMuted,
          width: 2,
        ),
      ),
      child: completed
          ? const Icon(
              Icons.check,
              size: 16,
              color: Colors.white,
            )
          : null,
    );
  }
}
