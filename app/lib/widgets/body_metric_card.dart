import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';

class BodyMetricCard extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double? previousValue;
  final IconData icon;
  final bool lowerIsBetter;

  const BodyMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.previousValue,
    required this.icon,
    this.lowerIsBetter = false,
  });

  @override
  Widget build(BuildContext context) {
    final change = previousValue != null ? value - previousValue! : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: GoogleFonts.rajdhani(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          if (change != null) ...[
            const SizedBox(height: 6),
            _TrendArrow(change: change, lowerIsBetter: lowerIsBetter),
          ],
        ],
      ),
    );
  }
}

class _TrendArrow extends StatelessWidget {
  final double change;
  final bool lowerIsBetter;

  const _TrendArrow({required this.change, required this.lowerIsBetter});

  @override
  Widget build(BuildContext context) {
    final isGood = (change < 0 && lowerIsBetter) || (change > 0 && !lowerIsBetter);
    final isNeutral = change.abs() < 0.05;
    final color = isNeutral ? AppColors.textMuted : (isGood ? AppColors.success : AppColors.error);
    final icon = isNeutral
        ? Icons.trending_flat
        : (change > 0 ? Icons.trending_up : Icons.trending_down);

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
