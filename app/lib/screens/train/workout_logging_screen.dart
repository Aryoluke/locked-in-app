import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/workout.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/rest_timer.dart';
import '../../widgets/set_row.dart';

class WorkoutLoggingScreen extends StatefulWidget {
  const WorkoutLoggingScreen({super.key, this.initialExercise});

  final String? initialExercise;

  @override
  State<WorkoutLoggingScreen> createState() => _WorkoutLoggingScreenState();
}

class _WorkoutLoggingScreenState extends State<WorkoutLoggingScreen> {
  final _notesController = TextEditingController();
  String? _selectedExercise;
  String? _selectedVariation;
  bool _showRestTimer = true;
  Duration _restDuration = const Duration(seconds: 90);

  static const _variations = [
    'Standard',
    'Close Grip',
    'Wide Grip',
    'Incline',
    'Decline',
    'Reverse',
    'Neutral',
    'Paused',
  ];

  @override
  void initState() {
    super.initState();
    _selectedExercise = widget.initialExercise;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _startNewWorkout() async {
    final wp = Provider.of<WorkoutProvider>(context, listen: false);
    await wp.startWorkout(name: 'Quick Session');
    if (mounted) setState(() {});
  }

  Future<void> _addSet() async {
    final wp = Provider.of<WorkoutProvider>(context, listen: false);
    final active = wp.activeWorkout;
    if (active == null) return;

    final nextNumber = wp.activeSets
            .fold<int>(0, (max, s) => s.setNumber > max ? s.setNumber : max) +
        1;
    final exerciseName =
        _selectedExercise ?? 'Exercise $nextNumber';
    await wp.addSet(WorkoutSet(
      exerciseId: exerciseName,
      exerciseName: exerciseName,
      setNumber: nextNumber,
    ));
    if (mounted) setState(() {});
  }

  Future<void> _finishWorkout() async {
    final wp = Provider.of<WorkoutProvider>(context, listen: false);
    final results = await wp.finishWorkout();
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (ctx) => _WorkoutSummarySheet(
        volume: results.volume,
        calories: results.calories,
        xp: results.xp,
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WorkoutProvider>();
    final sets = wp.activeSets;
    final active = wp.activeWorkout;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('WORKOUT'),
        actions: [
          if (active != null)
            TextButton(
              onPressed: _finishWorkout,
              child: const Text('Finish'),
            ),
        ],
      ),
      body: active == null
          ? _EmptyWorkoutState(onStart: _startNewWorkout)
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ===== Exercise name =====
                      _buildExerciseSelector(),
                      const SizedBox(height: 12),

                      // ===== Variation =====
                      _buildVariationSelector(),
                      const SizedBox(height: 4),

                      // ===== Superset toggle =====
                      Row(
                        children: [
                          const Text(
                            'Superset mode',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          Switch(
                            value: active.supersetMode,
                            activeColor: AppColors.primary,
                            onChanged: (_) {
                              Provider.of<WorkoutProvider>(context,
                                      listen: false)
                                  .toggleSuperset();
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ===== Sets header =====
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: const [
                            SizedBox(
                                width: 40,
                                child: Text('SET',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted))),
                            Expanded(
                                child: Text('REPS',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted))),
                            SizedBox(width: 56),
                            Expanded(
                                child: Text('WEIGHT',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted))),
                            SizedBox(width: 36),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // ===== Set rows =====
                      if (sets.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No sets yet. Add your first set below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      else
                        ...sets.map((s) => SetRow(
                              set: s,
                              onToggleComplete: () =>
                                  wp.toggleSetComplete(s),
                              onRepsChanged: (reps) => wp
                                  .updateSet(s.copyWith(reps: reps)),
                              onWeightChanged: (weight) => wp
                                  .updateSet(s.copyWith(weight: weight)),
                            )),

                      const SizedBox(height: 12),

                      // ===== Add set =====
                      OutlinedButton.icon(
                        onPressed: _addSet,
                        icon: const Icon(Icons.add),
                        label: const Text('ADD SET'),
                      ),
                      const SizedBox(height: 16),

                      // ===== Notes =====
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Session notes...',
                          prefixIcon: Icon(Icons.notes,
                              color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ===== Rest timer =====
                      if (_showRestTimer)
                        RestTimer(
                          duration: _restDuration,
                          onComplete: () {},
                        ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _showRestTimer = !_showRestTimer),
                        icon: Icon(
                          _showRestTimer
                              ? Icons.timer_off
                              : Icons.timer,
                          size: 18,
                        ),
                        label: Text(_showRestTimer
                            ? 'Hide rest timer'
                            : 'Show rest timer'),
                      ),
                    ],
                  ),
                ),

                // ===== Bottom finish bar =====
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _finishWorkout,
                        child: const Text('FINISH & EARN XP'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildExerciseSelector() {
    return InkWell(
      onTap: () => _showExercisePicker(),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Exercise',
          prefixIcon: Icon(Icons.fitness_center, color: AppColors.primary),
          suffixIcon: Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
        ),
        child: Text(
          _selectedExercise ?? 'Choose an exercise',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildVariationSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final v in _variations)
          ChoiceChip(
            label: Text(v),
            selected: _selectedVariation == v,
            onSelected: (_) => setState(() => _selectedVariation = v),
          ),
      ],
    );
  }

  void _showExercisePicker() {
    final wp = Provider.of<WorkoutProvider>(context, listen: false);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        var search = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = wp.library
                .where((e) => e.name.toLowerCase().contains(search.toLowerCase()))
                .toList();
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              builder: (context, scrollController) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Choose Exercise',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          onChanged: (v) =>
                              setSheetState(() => search = v),
                          decoration: const InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: Icon(Icons.search,
                                color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final e = filtered[index];
                        return ListTile(
                          leading: const Icon(Icons.fitness_center,
                              color: AppColors.primary),
                          title: Text(e.name),
                          subtitle: Text(e.bodyPart),
                          onTap: () {
                            setState(() => _selectedExercise = e.name);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyWorkoutState extends StatelessWidget {
  final VoidCallback onStart;

  const _EmptyWorkoutState({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 40,
                color: AppColors.primary,
              ),
            ).animate().scale(
                  begin: Offset(0.6, 0.6),
                  end: Offset(1, 1),
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 20),
            Text(
              'No workout active',
              style: GoogleFonts.rajdhani(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a fresh session and build your sets.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onStart,
              child: const Text('START WORKOUT'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutSummarySheet extends StatelessWidget {
  final double volume;
  final int calories;
  final int xp;
  final VoidCallback onClose;

  const _WorkoutSummarySheet({
    required this.volume,
    required this.calories,
    required this.xp,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final controller = DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              shape: BoxShape.circle,
            ),
            child: Text(
              '+$xp',
              style: GoogleFonts.rajdhani(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ).animate().scale(
                begin: Offset(0.4, 0.4),
                end: Offset(1, 1),
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 16),
          const Text(
            'WORKOUT COMPLETE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'You\'re one step closer. Keep the streak alive.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _summaryStat('Volume', '${volume.toStringAsFixed(0)} kg'),
              _summaryStat('Calories', '$calories kcal'),
              _summaryStat('XP Earned', '+$xp'),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onClose,
            child: const Text('DONE'),
          ),
        ],
      ),
    );

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: controller,
    );
  }

  Widget _summaryStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.rajdhani(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
