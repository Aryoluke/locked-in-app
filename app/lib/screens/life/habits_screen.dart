import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/habit_tile.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final _nameController = TextEditingController();
  String _icon = '✅';
  String _category = 'discipline';

  static const _categoryIcons = {
    'health': '💪',
    'mind': '🧠',
    'discipline': '⚔️',
    'social': '🤝',
    'custom': '✨',
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addHabit() async {
    _nameController.clear();
    _icon = '✅';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('New Habit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Habit name',
                  hintText: 'e.g. Morning walk',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                children: [
                  for (final e in _categoryIcons.entries)
                    ChoiceChip(
                      avatar: Text(e.value),
                      label: Text(e.key),
                      selected: _category == e.key,
                      onSelected: (_) => setSheetState(() {
                        _category = e.key;
                        _icon = e.value;
                      }),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && _nameController.text.trim().isNotEmpty) {
      await Provider.of<HabitProvider>(context, listen: false).addHabit(
        Habit(
          name: _nameController.text.trim(),
          icon: _icon,
          category: _category,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsProvider = context.watch<HabitProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('HABITS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: _addHabit,
          ),
        ],
      ),
      body: habitsProvider.habits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.checklist,
                      size: 60, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text(
                    'No habits yet.\nAdd one to start building your streak.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _addHabit,
                    icon: const Icon(Icons.add),
                    label: const Text('ADD HABIT'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: habitsProvider.habits.length,
              itemBuilder: (context, index) {
                final h = habitsProvider.habits[index];
                return HabitTile(
                  habit: h,
                  completedToday: habitsProvider.isCompletedToday(h),
                  todayCount: habitsProvider.completedCountToday(h),
                  onToggle: (habit) =>
                      Provider.of<HabitProvider>(context, listen: false)
                          .toggleHabit(habit),
                  onDelete: (habit) =>
                      Provider.of<HabitProvider>(context, listen: false)
                          .deleteHabit(habit.id),
                );
              },
            ),
    );
  }
}
