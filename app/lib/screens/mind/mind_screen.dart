import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/study_provider.dart';
import '../../screens/mind/pomodoro_screen.dart';

class MindScreen extends StatelessWidget {
  const MindScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('MIND'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Study'),
              Tab(text: 'Pomodoro'),
              Tab(text: 'Mood'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _StudyTab(),
            _PomodoroTab(),
            _MoodTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.study),
          backgroundColor: AppColors.mindColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Study'),
        ),
      ),
    );
  }
}

class _StudyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Subjects + hours
        _StudyStats(study: study),
        const SizedBox(height: 16),
        const Text(
          'RECENT SESSIONS',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        if (study.studyLogs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No study sessions yet.\nTap "Start Study" to begin your focus block.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...study.studyLogs.take(10).map((log) => ListTile(
                leading: const Icon(Icons.school, color: AppColors.mindColor),
                title: Text(log.subject),
                subtitle: Text(log.topic ?? 'Focus session'),
                trailing: Text(
                  '${log.minutes}m',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
      ],
    );
  }
}

class _StudyStats extends StatelessWidget {
  final StudyProvider study;
  const _StudyStats({required this.study});

  @override
  Widget build(BuildContext context) {
    final todayMinutes = study.studyLogs
        .where((l) {
          final now = DateTime.now();
          return l.date.year == now.year &&
              l.date.month == now.month &&
              l.date.day == now.day;
        })
        .fold(0, (sum, l) => sum + l.minutes);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(context, '${todayMinutes}m', 'Today'),
          _stat(context, '${study.subjects.length}', 'Subjects'),
          _stat(
              context,
              '${study.studyLogs.fold(0, (s, l) => s + l.minutes) ~/ 60}h',
              'Total'),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.rajdhani(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.mindColor,
          ),
        ),
        Text(label, style: const TextStyle(color: AppColors.textMuted)),
      ],
    );
  }
}

class _PomodoroTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();

    return PomodoroTimerWidget(study: study);
  }
}

class _MoodTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();
    int energy = 3;
    int mood = 3;
    int motivation = 3;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'HOW ARE YOU FEELING?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        _MoodSlider(
          label: 'Energy',
          icon: Icons.bolt,
          onChanged: (v) => energy = v,
        ),
        _MoodSlider(
          label: 'Mood',
          icon: Icons.sentiment_satisfied,
          onChanged: (v) => mood = v,
        ),
        _MoodSlider(
          label: 'Motivation',
          icon: Icons.flag,
          onChanged: (v) => motivation = v,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            Provider.of<StudyProvider>(context, listen: false)
                .checkInMood(energy, mood, motivation);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mood check-in saved')),
            );
          },
          icon: const Icon(Icons.check),
          label: const Text('SAVE CHECK-IN'),
        ),
        const SizedBox(height: 24),
        const Text(
          'CHECK-IN HISTORY',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        if (study.moodHistory.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No check-ins yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...study.moodHistory.take(10).map((m) => ListTile(
                leading: const Icon(Icons.face, color: AppColors.mindColor),
                title: Text(_moodText(m.mood)),
                subtitle: Text(
                  'Energy ${m.energy} · Mood ${m.mood} · Motivation ${m.motivation}',
                ),
                trailing: Text(
                  _timeAgo(m.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              )),
      ],
    );
  }

  String _moodText(int mood) {
    if (mood >= 5) return 'Feeling amazing 🚀';
    if (mood >= 4) return 'Pretty good 😄';
    if (mood >= 3) return 'Okay 😐';
    if (mood >= 2) return 'Struggling 😕';
    return 'Rough day 😞';
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _MoodSlider extends StatefulWidget {
  final String label;
  final IconData icon;
  final ValueChanged<int> onChanged;

  const _MoodSlider({
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  @override
  State<_MoodSlider> createState() => _MoodSliderState();
}

class _MoodSliderState extends State<_MoodSlider> {
  double _value = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(widget.icon, color: AppColors.mindColor, size: 20),
              const SizedBox(width: 8),
              Text(widget.label,
                  style: const TextStyle(color: AppColors.textPrimary)),
              const Spacer(),
              _emoji(_value.round()),
            ],
          ),
          Slider(
            value: _value,
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: AppColors.mindColor,
            inactiveColor: AppColors.surfaceElevated,
            onChanged: (v) {
              setState(() => _value = v);
              widget.onChanged(v.round());
            },
          ),
        ],
      ),
    );
  }

  Widget _emoji(int v) {
    const emojis = ['😞', '😕', '😐', '😄', '🚀'];
    final index = (v - 1).clamp(0, 4);
    return Text(
      emojis[index],
      style: const TextStyle(fontSize: 24),
    );
  }
}
