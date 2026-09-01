import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/study_provider.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  String _selectedSubject = 'General';
  String? _topic;
  int _focusScore = 5;

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();
    final subjects = study.subjects;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('STUDY TRACKER'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Subject selection
          const Text(
            'SUBJECT',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in subjects)
                ChoiceChip(
                  label: Text('${s.name} · ${s.hours.toStringAsFixed(0)}h'),
                  selected: _selectedSubject == s.name,
                  onSelected: (_) =>
                      setState(() => _selectedSubject = s.name),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Topic
          TextField(
            decoration: const InputDecoration(
              labelText: 'Topic (optional)',
              hintText: 'e.g. Calculus 2 integrals',
              prefixIcon: Icon(Icons.subject, color: AppColors.textMuted),
            ),
            onChanged: (v) => _topic = v,
          ),
          const SizedBox(height: 16),

          // Add subject
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addSubject(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add subject'),
            ),
          ),

          const SizedBox(height: 8),

          // Log block (minutes)
          const Text(
            'LOG STUDY SESSION',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _log(15),
                  icon: const Icon(Icons.timer, size: 18),
                  label: const Text('15 min'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _log(30),
                  icon: const Icon(Icons.timer, size: 18),
                  label: const Text('30 min'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _log(60),
                  icon: const Icon(Icons.timer, size: 18),
                  label: const Text('1 hour'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _log(25),
                  icon: const Icon(Icons.adjust, size: 18),
                  label: const Text('1 Pomodoro'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _log(int minutes) {
    final study = Provider.of<StudyProvider>(context, listen: false);
    study.logStudy(
      subject: _selectedSubject,
      topic: _topic,
      minutes: minutes,
      pomodoros: minutes == 25 ? 1 : 0,
      focusScore: _focusScore,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged $minutes min of $_selectedSubject')),
    );
  }

  Future<void> _addSubject(BuildContext context) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('New Subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Subject name'),
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
    if (confirmed == true && controller.text.trim().isNotEmpty) {
      await Provider.of<StudyProvider>(context, listen: false)
          .addSubject(controller.text.trim());
    }
  }
}
