import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';

class SkinScreen extends StatefulWidget {
  const SkinScreen({super.key});

  @override
  State<SkinScreen> createState() => _SkinScreenState();
}

class _SkinScreenState extends State<SkinScreen> {
  // AM routine
  final _amRoutine = <_RoutineItem>[
    _RoutineItem('Cleanser', 'Wash face with gentle cleanser', Icons.face),
    _RoutineItem('Toner', 'Apply toner to balance skin', Icons.water_drop),
    _RoutineItem('Moisturizer', 'Hydrate with light moisturizer', Icons.spa),
    _RoutineItem('SPF', 'Apply sunscreen (non-negotiable)', Icons.beach_access),
  ];

  // PM routine
  final _pmRoutine = <_RoutineItem>[
    _RoutineItem('Double Cleanse', 'Oil then foam cleanser', Icons.face_retouching_natural),
    _RoutineItem('Exfoliate (2-3x wk)', 'Gentle chemical exfoliant', Icons.bubble_chart),
    _RoutineItem('Serum', 'Active serum for your goals', Icons.science),
    _RoutineItem('Moisturizer', 'Night cream for repair', Icons.bedtime),
    _RoutineItem('Lip balm', 'Hydrate lips overnight', Icons.face_2),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SKINCARE & CARE'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Grooming checklist
          _SectionHeader('GROOMING DAILY'),
          const SizedBox(height: 8),
          _GroomingChecklist(),
          const SizedBox(height: 24),

          // AM Routine
          _SectionHeader('AM ROUTINE'),
          const SizedBox(height: 8),
          _RoutineCard(title: 'MORNING', items: _amRoutine, icon: Icons.wb_sunny, storageKey: 'skin_am_routine'),
          const SizedBox(height: 24),

          // PM Routine
          _SectionHeader('PM ROUTINE'),
          const SizedBox(height: 8),
          _RoutineCard(title: 'EVENING', items: _pmRoutine, icon: Icons.nightlight, storageKey: 'skin_pm_routine'),
          const SizedBox(height: 24),

          // Supplements
          _SectionHeader('SUPPLEMENTS'),
          const SizedBox(height: 8),
          const _SupplementTracker(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.rajdhani(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _RoutineItem {
  final String title;
  final String subtitle;
  final IconData icon;

  _RoutineItem(this.title, this.subtitle, this.icon);
}

class _RoutineCard extends StatefulWidget {
  final String title;
  final List<_RoutineItem> items;
  final IconData icon;
  final String storageKey;

  const _RoutineCard({
    required this.title,
    required this.items,
    required this.icon,
    required this.storageKey,
  });

  @override
  State<_RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends State<_RoutineCard> {
  final Set<int> _completed = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(widget.storageKey) ?? const [];
    if (!mounted) return;
    setState(() {
      _completed
        ..clear()
        ..addAll(stored.map(int.parse));
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      widget.storageKey,
      _completed.map((i) => i.toString()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(widget.icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: GoogleFonts.rajdhani(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_completed.length}/${widget.items.length}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...List.generate(widget.items.length, (index) {
            final item = widget.items[index];
            final isDone = _completed.contains(index);
            return InkWell(
              onTap: () => setState(() {
                if (isDone) {
                  _completed.remove(index);
                } else {
                  _completed.add(index);
                }
                _save();
              }),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isDone ? AppColors.primary : AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Icon(item.icon,
                        color: isDone ? AppColors.primary : AppColors.textSecondary,
                        size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: isDone
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _GroomingChecklist extends StatefulWidget {
  @override
  State<_GroomingChecklist> createState() => _GroomingChecklistState();
}

class _GroomingChecklistState extends State<_GroomingChecklist> {
  static const _items = [
    'Shower & freshen up',
    'Brush teeth (AM & PM)',
    'Floss',
    'Deodorant',
    'Trim nails',
    'Hair in check',
  ];

  final Set<int> _done = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('skin_grooming') ?? const [];
    if (!mounted) return;
    setState(() {
      _done
        ..clear()
        ..addAll(stored.map(int.parse));
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'skin_grooming',
      _done.map((i) => i.toString()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++)
            InkWell(
              onTap: () => setState(() {
                if (_done.contains(i)) {
                  _done.remove(i);
                } else {
                  _done.add(i);
                }
                _save();
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      _done.contains(i)
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: _done.contains(i)
                          ? AppColors.primary
                          : AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _items[i],
                      style: TextStyle(
                        color: _done.contains(i)
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        decoration: _done.contains(i)
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SupplementTracker extends StatefulWidget {
  const _SupplementTracker();

  @override
  State<_SupplementTracker> createState() => _SupplementTrackerState();
}

class _SupplementTrackerState extends State<_SupplementTracker> {
  static const _supplements = [
    'Protein',
    'Creatine',
    'Multivitamin',
    'Omega-3',
    'Vitamin D',
  ];

  final Set<String> _taken = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('skin_supplements') ?? const [];
    if (!mounted) return;
    setState(() => _taken..clear()..addAll(stored));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('skin_supplements', _taken.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in _supplements)
            FilterChip(
              avatar: Icon(
                _taken.contains(s) ? Icons.check : Icons.medication,
                size: 18,
                color: _taken.contains(s)
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
              label: Text(s),
              selected: _taken.contains(s),
              onSelected: (_) => setState(() {
                if (_taken.contains(s)) {
                  _taken.remove(s);
                } else {
                  _taken.add(s);
                }
                _save();
              }),
            ),
        ],
      ),
    );
  }
}
