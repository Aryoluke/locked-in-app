import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/theme.dart';
import '../../models/workout.dart';
import '../../providers/workout_provider.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String _search = '';
  String? _selectedCategory;
  TextEditingController? _nameController;
  TextEditingController? _partController;

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WorkoutProvider>();

    final categories = wp.library.map((e) => e.bodyPart).toSet().toList()
      ..sort();

    final filtered = wp.library.where((e) {
      final matchesSearch =
          e.name.toLowerCase().contains(_search.toLowerCase());
      final matchesCategory =
          _selectedCategory == null || e.bodyPart == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('EXERCISE LIBRARY'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _addCustomExercise(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _categoryChip(null, 'All'),
                for (final c in categories) _categoryChip(c, c),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No exercises found',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final e = filtered[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _iconFor(e.bodyPart),
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(e.name),
                        subtitle: Text(
                          e.bodyPart,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        trailing: e.isCustom
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.error, size: 20),
                                onPressed: () => _deleteExercise(e.id),
                              )
                            : const Icon(Icons.chevron_right,
                                color: AppColors.textMuted),
                      ).animate().fadeIn(delay: (index ~/ 10 * 50).ms);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String? value, String label) {
    final selected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedCategory = value),
      ),
    );
  }

  IconData _iconFor(String part) {
    switch (part.toLowerCase()) {
      case 'chest':
        return Icons.view_week;
      case 'back':
        return Icons.view_agenda;
      case 'shoulders':
        return Icons.panorama_horizontal;
      case 'legs':
        return Icons.directions_walk;
      case 'cardio':
        return Icons.directions_run;
      default:
        return Icons.fitness_center;
    }
  }

  Future<void> _addCustomExercise(BuildContext context) async {
    _nameController = TextEditingController();
    _partController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Custom Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g. Cable Crunch',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _partController,
              decoration: const InputDecoration(
                labelText: 'Body Part',
                hintText: 'e.g. Core',
              ),
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
    );

    if (confirmed == true &&
        _nameController!.text.trim().isNotEmpty) {
      final exercise = Exercise(
        id: const Uuid().v4(),
        name: _nameController!.text.trim(),
        bodyPart:
            _partController!.text.trim().isEmpty ? 'Custom' : _partController!.text.trim(),
        isCustom: true,
      );
      await Provider.of<WorkoutProvider>(context, listen: false)
          .addCustomExercise(exercise);
    }
  }

  Future<void> _deleteExercise(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Exercise'),
        content: const Text('Are you sure you want to remove this custom exercise?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await Provider.of<WorkoutProvider>(context, listen: false)
        .deleteCustomExercise(id);
  }
}
