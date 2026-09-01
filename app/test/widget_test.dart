// LOCKED IN - smoke tests.
//
// These test pure, dependency-free logic so they run without a device/emulator
// and without mocking platform channels (sqflite, notifications, etc. are not
// exercised here — they need the full app runtime).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locked_in/config/theme.dart';

void main() {
  test('Brand palette: dark charcoal background', () {
    expect(AppColors.background, const Color(0xFF141416));
  });

  test('Brand palette: emerald primary', () {
    expect(AppColors.primary, const Color(0xFF10B981));
  });

  test('Brand palette: gold accent', () {
    expect(AppColors.gold, const Color(0xFFD4AF37));
  });

  test('Brand palette: neon XP green', () {
    expect(AppColors.neonGreen, const Color(0xFF39FF14));
  });

  test('AppTheme exposes a dark theme', () {
    final theme = AppTheme.darkTheme;
    expect(theme.brightness, Brightness.dark);
  });
}
