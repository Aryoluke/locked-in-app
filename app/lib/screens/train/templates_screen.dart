import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/workout.dart';
import '../../providers/workout_provider.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _newTemplate() async {
    _nameController.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('New Template'),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Template Name',
            hintText: 'e.g. Push Day',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed == true && _nameController.text.trim().isNotEmpty) {
      await Provider.of<WorkoutProvider>(context, listen: false).saveTemplate(
        WorkoutTemplate(name: _nameController.text.trim()),
      );
    }
  }

  Future<void> _delete(String id) async {
    await Provider.of<WorkoutProvider>(context, listen: false).deleteTemplate(id);
  }

  @override
  Widget build(BuildContext context) {
    final templates = context.watch<WorkoutProvider>().templates;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('TEMPLATES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: _newTemplate,
          ),
        ],
      ),
      body: templates.isEmpty
          ? const Center(
              child: Text(
                'No templates yet.\nTap + to create one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final t = templates[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.name,
                              style: GoogleFonts.rajdhani(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error, size: 20),
                            onPressed: () => _delete(t.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.exerciseNames.length} exercises · ~${t.estimatedDurationMin} min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (t.exerciseNames.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...t.exerciseNames
                            .take(4)
                            .map((e) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.fitness_center,
                                          size: 14,
                                          color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        e,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                )),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('START'),
                          onPressed: () {
                            Provider.of<WorkoutProvider>(context, listen: false)
                                .startWorkout(
                              name: t.name,
                              templateId: t.id,
                              exerciseNames: t.exerciseNames,
                            );
                            Navigator.pushNamed(context, AppRoutes.workoutLog);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
