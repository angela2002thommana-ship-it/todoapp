import 'dart:math' as math;
import 'package:flutter/material.dart';

class PiePainter extends CustomPainter {
  final double done;
  final double remaining;

  PiePainter(
    this.done,
    this.remaining,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final total = done + remaining;
    final diameter = size.shortestSide * .90;
    final radius = diameter / 2;
    final center = size.center(Offset.zero);

    final rect = Rect.fromCenter(
      center: center,
      width: diameter,
      height: diameter,
    );

    if (total <= 0) {
      final backgroundPaint = Paint()
        ..color = Colors.grey.shade200;

      canvas.drawCircle(center, radius, backgroundPaint);
      return;
    }

    final angle = (done / total).clamp(0.0, 1.0) *
        2 *
        math.pi;

    final completedPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.fromARGB(255, 170, 201, 240),
          Color(0xFF61A5FA),
          Color.fromARGB(255, 22, 6, 167),
          Color.fromARGB(255, 15, 4, 116),

        ],
      ).createShader(rect);

    if (angle > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        angle,
        true,
        completedPaint,
      );
    }

    final remainingPaint = Paint()
      ..color = Colors.grey.shade200;

    if (angle < 2 * math.pi) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + angle,
        2 * math.pi - angle,
        true,
        remainingPaint,
      );
    }

    final centerPaint = Paint()
      ..color = Colors.white;

    canvas.drawCircle(
      center,
      radius * .6,
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant PiePainter old) {
    return old.done != done ||
        old.remaining != remaining;
  }
}
