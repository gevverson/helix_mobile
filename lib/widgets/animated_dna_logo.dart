import 'dart:math';
import 'package:flutter/material.dart';
import '../config/app_constants.dart';

/// An animated DNA double helix widget for splash and branding.
class AnimatedDnaLogo extends StatefulWidget {
  final double size;
  final Duration duration;

  const AnimatedDnaLogo({
    super.key,
    this.size = 120,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedDnaLogo> createState() => _AnimatedDnaLogoState();
}

class _AnimatedDnaLogoState extends State<AnimatedDnaLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size * 1.2),
          painter: _DnaHelixPainter(_controller.value),
        );
      },
    );
  }
}

class _DnaHelixPainter extends CustomPainter {
  final double progress;

  _DnaHelixPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final amplitude = size.width * 0.28;
    final steps = 20;
    final segmentHeight = size.height / steps;

    final cyanPaint = Paint()
      ..color = AppConstants.accentCyan
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final purplePaint = Paint()
      ..color = AppConstants.accentPurple
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppConstants.borderColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.2;

    for (int i = 0; i <= steps; i++) {
      final y = i * segmentHeight;
      final phase = (i / steps) * 2 * pi + progress * 2 * pi;

      final x1 = centerX + amplitude * sin(phase);
      final x2 = centerX - amplitude * sin(phase);

      // Connector lines
      canvas.drawLine(Offset(x1, y), Offset(x2, y), linePaint);

      // Strand 1 (cyan)
      final radius1 = 4.0 + 2.0 * ((sin(phase) + 1) / 2);
      cyanPaint.color = AppConstants.accentCyan
          .withValues(alpha: 0.5 + 0.5 * ((sin(phase) + 1) / 2));
      canvas.drawCircle(Offset(x1, y), radius1, cyanPaint);

      // Strand 2 (purple)
      final radius2 = 4.0 + 2.0 * (((-sin(phase)) + 1) / 2);
      purplePaint.color = AppConstants.accentPurple
          .withValues(alpha: 0.5 + 0.5 * (((-sin(phase)) + 1) / 2));
      canvas.drawCircle(Offset(x2, y), radius2, purplePaint);
    }

    // Glow effect at center
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppConstants.accentCyan.withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(centerX, size.height / 2), radius: size.width * 0.5),
      );
    canvas.drawCircle(
      Offset(centerX, size.height / 2),
      size.width * 0.5,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_DnaHelixPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
