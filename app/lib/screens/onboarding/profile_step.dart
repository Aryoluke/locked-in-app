import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';

class ProfileStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(String key, dynamic value) onChanged;
  final VoidCallback onNext;

  const ProfileStep({
    super.key,
    required this.data,
    required this.onChanged,
    required this.onNext,
  });

  @override
  State<ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<ProfileStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _ageController;
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data['name']?.toString() ?? '');
    _heightController = TextEditingController(text: widget.data['height']?.toString() ?? '');
    _weightController = TextEditingController(text: widget.data['weight']?.toString() ?? '');
    _ageController = TextEditingController(text: widget.data['age']?.toString() ?? '');
    _dob = widget.data['dob'] as DateTime?;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        widget.onChanged('dob', picked);
        final age = DateTime.now().year - picked.year;
        _ageController.text = '$age';
        widget.onChanged('age', age);
      });
    }
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    widget.onChanged('name', _nameController.text.trim());
    widget.onChanged('height', double.tryParse(_heightController.text) ?? 0);
    widget.onChanged('weight', double.tryParse(_weightController.text) ?? 0);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Step 2 · Profile',
                style: GoogleFonts.rajdhani(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us about you',
                style: GoogleFonts.rajdhani(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.person_outline,
                      color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        prefixIcon: Icon(Icons.height,
                            color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        prefixIcon: Icon(Icons.monitor_weight_outlined,
                            color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // DOB
              InkWell(
                onTap: _pickDob,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.cake_outlined,
                        color: AppColors.textMuted),
                    suffixIcon: Icon(Icons.calendar_today,
                        color: AppColors.textMuted, size: 18),
                  ),
                  child: Text(
                    _dob == null
                        ? 'Tap to select'
                        : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                    style: TextStyle(
                      color: _dob == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ageController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.tag, color: AppColors.textMuted),
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continue,
                  child: const Text('CONTINUE'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
