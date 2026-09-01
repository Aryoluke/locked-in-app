import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';

class RestTimer extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onComplete;

  const RestTimer({
    super.key,
    required this.duration,
    this.onComplete,
  });

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> {
  late Duration _remaining;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      _running = false;
    } else {
      _running = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remaining.inSeconds <= 1) {
          _timer?.cancel();
          _running = false;
          _remaining = Duration.zero;
          _hapticBuzz();
          widget.onComplete?.call();
          setState(() {});
        } else {
          setState(() => _remaining -= const Duration(seconds: 1));
          // Haptic at final 5 seconds
          if (_remaining.inSeconds <= 5 && _remaining.inSeconds > 0) {
            HapticFeedback.vibrate();
          }
        }
      });
    }
    setState(() {});
  }

  void _hapticBuzz() {
    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();
  }

  void _reset() {
    _timer?.cancel();
    _running = false;
    setState(() => _remaining = widget.duration);
  }

  @override
  Widget build(BuildContext context) {
    final totalSec = widget.duration.inSeconds;
    final remainingSec = _remaining.inSeconds;
    final progress = totalSec > 0 ? remainingSec / totalSec : 0.0;
    final minutes = remainingSec ~/ 60;
    final seconds = remainingSec % 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: AppColors.primary, size: 28),
              const SizedBox(width: 8),
              Text(
                'REST',
                style: GoogleFonts.rajdhani(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (_running)
                TextButton(
                  onPressed: _toggle,
                  child: const Text('Pause'),
                )
              else
                TextButton(
                  onPressed: _toggle,
                  child: Text(_remaining == widget.duration ? 'Start' : 'Resume'),
                ),
              IconButton(
                onPressed: _reset,
                icon: const Icon(Icons.refresh, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: GoogleFonts.rajdhani(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: _remaining == Duration.zero
                            ? AppColors.neonGreen
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _running ? 'Get ready for next set' : 'Set your rest time',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_remaining == Duration.zero)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'TIME\'S UP — GET BACK IN',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
                begin: 1.0, end: 0.4, duration: 800.ms),
        ],
      ),
    );
  }
}
