import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/theme.dart';

class StreakFlame extends StatefulWidget {
  final int count;
  final double size;

  const StreakFlame({
    super.key,
    required this.count,
    this.size = 48,
  });

  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _flameColor {
    if (widget.count >= 21) return AppColors.neonGreen;
    if (widget.count >= 14) return Colors.orange;
    if (widget.count >= 7) return Colors.amber;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.08);
        return Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                painter: _FlamePainter(
                  color: _flameColor,
                  intensity: _controller.value,
                ),
                size: Size(size, size * 1.1),
              ),
              Text(
                '${widget.count}',
                style: GoogleFontsRajdhaniBold(
                  fontSize: size * 0.5,
                  color: _flameColor,
                ),
              ),
            ],
          ),
        );
      },
    ).animate(onPlay: (c) => c.repeat()).shakeX(
          amount: 2,
          duration: 1.4.seconds,
          curve: Curves.easeInOut,
        );
  }
}

class _FlamePainter extends CustomPainter {
  final Color color;
  final double intensity;

  _FlamePainter({required this.color, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    final inner = Paint()
      ..color = AppColors.gold.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height * 0.72);
    final radius = size.width * 0.4 * (1 + intensity * 0.1);

    // Outer flame blob
    final outerPath = Path()
      ..moveTo(center.dx, center.dy)
      ..quadraticBezierTo(
        center.dx - radius * 1.2,
        center.dy - radius * 0.6,
        center.dx,
        center.dy - radius * 1.8,
      )
      ..quadraticBezierTo(
        center.dx + radius * 0.6,
        center.dy - radius * 0.2,
        center.dx,
        center.dy,
      )
      ..close();
    canvas.drawPath(outerPath, outer);

    // Inner bright core
    canvas.drawCircle(
      center.translate(0, -radius * 0.3),
      radius * 0.45,
      inner,
    );
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.intensity != intensity;
}

TextStyle GoogleFontsRajdhaniBold({double fontSize = 16, Color color = AppColors.textPrimary}) {
  return TextStyle(
    fontFamily: 'Rajdhani',
    fontWeight: FontWeight.w700,
    fontSize: fontSize,
    color: color,
    letterSpacing: -1,
  );
}
