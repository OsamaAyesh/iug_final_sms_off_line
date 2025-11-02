import 'package:flutter/material.dart';

class WavePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw diagonal curved wave lines for modern effect
    for (int i = 0; i < 12; i++) {
      final path = Path();
      final startX = -50.0 + (i * 60.0);
      path.moveTo(startX, 0);

      // Create smooth curved wave pattern
      for (double y = 0; y <= size.height; y += 15) {
        final xOffset = (y * 0.25) + (20 * sin(y / 50));
        path.lineTo(startX + xOffset, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(WavePatternPainter oldDelegate) => false;
}

// Helper function for sine calculation
double sin(double x) {
  const double pi = 3.14159265359;
  x = x % (2 * pi);
  const double a1 = 1.0;
  const double a3 = -1.0 / 6.0;
  const double a5 = 1.0 / 120.0;
  const double a7 = -1.0 / 5040.0;

  double x2 = x * x;
  return a1 * x + a3 * x * x2 + a5 * x * x2 * x2 + a7 * x * x2 * x2 * x2;
}