import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/workout.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/workout_card.dart';

class TrainScreen extends StatefulWidget {
  const TrainScreen({super.key});

  @override
  State<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends State<TrainScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('TRAIN'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
            Tab(text: 'Templates'),
            Tab(text: 'Library'),
            Tab(text: 'PRs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveTab(),
          _HistoryTab(),
          _TemplatesTab(),
          _LibraryTab(),
          _PrsTab(),
        ],
      ),
    );
  }
}

// ===== Active =====
class _ActiveTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workouts = context.watch<WorkoutProvider>();
    final active = workouts.activeWorkout;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WORKOUT IN PROGRESS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  active.name ?? 'Current Session',
                  style: GoogleFonts.rajdhani(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${workouts.activeSets.length} sets logged',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.workoutLog),
                    child: const Text('RESUME'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.workoutLog),
            child: const Text('ADD SETS'),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No active workout',
                  style: GoogleFonts.rajdhani(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Start a session and get LOCKED IN',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.workoutLog),
                  child: const Text('START WORKOUT'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ===== History =====
class _HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workouts = context.watch<WorkoutProvider>();
    final history = workouts.history;

    if (history.isEmpty) {
      return const Center(
        child: Text(
          'No workouts yet.\nFinish your first session to see history.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final w = history[index];
        return WorkoutCard(
          workout: w,
          exerciseCount: 0,
        );
      },
    );
  }
}

// ===== Templates =====
class _TemplatesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workouts = context.watch<WorkoutProvider>();
    final templates = workouts.templates;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: () => _showNewTemplateDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('NEW TEMPLATE'),
        ),
        const SizedBox(height: 16),
        if (templates.isEmpty)
          const Center(
            child: Text(
              'Save a workout as a template to reuse it.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...templates.map((t) => _TemplateTile(template: t)),
      ],
    );
  }

  void _showNewTemplateDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('New Template'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Template Name',
            hintText: 'e.g. Push Day',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Provider.of<WorkoutProvider>(context, listen: false)
                    .saveTemplate(
                  WorkoutTemplate(
                    name: nameController.text.trim(),
                    exerciseNames: const [],
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// ===== Library =====
class _LibraryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workouts = context.watch<WorkoutProvider>();
    final library = workouts.library;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search exercises...',
              prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
            ),
            onChanged: (_) {},
          ),
        ),
        Expanded(
          child: library.isEmpty
              ? const Center(
                  child: Text(
                    'Exercise library loading...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  itemCount: library.length,
                  itemBuilder: (context, index) {
                    final e = library[index];
                    return ListTile(
                      leading: const Icon(Icons.fitness_center,
                          color: AppColors.primary),
                      title: Text(e.name),
                      subtitle: Text(e.bodyPart),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.workoutLog,
                            arguments: e.name);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ===== PRs =====
class _PrsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workouts = context.watch<WorkoutProvider>();
    final prs = workouts.personalRecords;

    if (prs.isEmpty) {
      return const Center(
        child: Text(
          'No personal records yet.\nLog heavy lifts to set PRs.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prs.length,
      itemBuilder: (context, index) {
        final pr = prs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pr.exerciseName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${pr.weight.toStringAsFixed(0)}kg × ${pr.reps}',
                style: GoogleFonts.rajdhani(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===== Template tile =====
class _TemplateTile extends StatelessWidget {
  final dynamic template;

  const _TemplateTile({required this.template});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name ?? 'Template',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${template.exerciseNames?.length ?? 0} exercises',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_circle,
                color: AppColors.primary, size: 32),
            onPressed: () {
              Provider.of<WorkoutProvider>(context, listen: false).startWorkout(
                name: template.name ?? 'Template',
                templateId: template.id ?? '',
                exerciseNames: List<String>.from(template.exerciseNames ?? []),
              );
              Navigator.pushNamed(context, AppRoutes.workoutLog);
            },
          ),
        ],
      ),
    );
  }
}

