import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/study_provider.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('POMODORO'),
      ),
      body: PomodoroTimerWidget(study: study),
    );
  }
}

/// Reusable pomodoro timer UI + logic wired to [StudyProvider].
class PomodoroTimerWidget extends StatelessWidget {
  final StudyProvider study;

  const PomodoroTimerWidget({super.key, required this.study});

  @override
  Widget build(BuildContext context) {
    final remaining = study.pomodoroRemaining;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    final progress = study.pomodoroProgress;
    final phaseColor = _phaseColor();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Phase label
        Center(
          child: Text(
            _phaseLabel(),
            style: GoogleFonts.rajdhani(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: phaseColor,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Completed pomodoros
        Center(
          child: Text(
            '${study.completedPomodoros} pomodoros completed today',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Timer ring
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 230,
                height: 230,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation(phaseColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: GoogleFonts.rajdhani(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    study.pomodoroRunning
                        ? (study.pomodoroPaused ? 'Paused' : 'Focused')
                        : 'Ready',
                    style: TextStyle(
                      fontSize: 14,
                      color: study.pomodoroRunning
                          ? (study.pomodoroPaused
                              ? AppColors.warning
                              : AppColors.success)
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Controls
        if (!study.pomodoroRunning)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _PresetButton(
                      label: '25m',
                      onTap: () => study.startPomodoro(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PresetButton(
                      label: '45m',
                      onTap: () => study.startPomodoro(minutes: 45),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PresetButton(
                      label: '60m',
                      onTap: () => study.startPomodoro(minutes: 60),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => study.startPomodoro(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('START FOCUS'),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: study.pausePomodoro,
                  icon: Icon(study.pomodoroPaused
                      ? Icons.play_arrow
                      : Icons.pause),
                  label: Text(study.pomodoroPaused ? 'Resume' : 'Pause'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: study.resetPomodoro,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),

        // Tag selector when idle
        if (!study.pomodoroRunning)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FOCUS TAG',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: const [
                  ChoiceChip(label: Text('Study'), selected: true),
                  ChoiceChip(label: Text('Work'), selected: false),
                  ChoiceChip(label: Text('Deep Work'), selected: false),
                  ChoiceChip(label: Text('Creation'), selected: false),
                ],
              ),
            ],
          ),
      ],
    );
  }

  String _phaseLabel() {
    switch (study.pomodoroPhase) {
      case 'work':
        return study.pomodoroRunning ? 'FOCUS' : 'POMODORO';
      case 'short_break':
        return 'SHORT BREAK';
      case 'long_break':
        return 'LONG BREAK';
      default:
        return 'POMODORO';
    }
  }

  Color _phaseColor() {
    switch (study.pomodoroPhase) {
      case 'work':
        return AppColors.primary;
      case 'short_break':
        return AppColors.success;
      case 'long_break':
        return AppColors.mindColor;
      default:
        return AppColors.primary;
    }
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.rajdhani(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
