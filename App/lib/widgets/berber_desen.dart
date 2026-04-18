import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tarak ve makas şekillerini arka plana çizer.
class BerberDesenWidget extends StatelessWidget {
  const BerberDesenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _BerberPainter()),
    );
  }
}

class _BerberPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.gold.withOpacity(0.055)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Birkaç konum ve açıda tarak ve makas çiz
    _drawScissors(canvas, paint, Offset(size.width * 0.1, size.height * 0.12), -0.3);
    _drawComb(canvas, paint, Offset(size.width * 0.78, size.height * 0.08), 0.4);
    _drawScissors(canvas, paint, Offset(size.width * 0.85, size.height * 0.5), 1.1);
    _drawComb(canvas, paint, Offset(size.width * 0.05, size.height * 0.6), -0.5);
    _drawScissors(canvas, paint, Offset(size.width * 0.45, size.height * 0.88), 0.2);
    _drawComb(canvas, paint, Offset(size.width * 0.6, size.height * 0.35), 0.8);
  }

  void _drawScissors(Canvas canvas, Paint paint, Offset center, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    const h = 45.0; // uzunluk
    const spread = 12.0;

    // Üst bıçak
    canvas.drawLine(const Offset(0, 0), Offset(h, -spread), paint);
    // Alt bıçak
    canvas.drawLine(const Offset(0, 0), Offset(h, spread), paint);
    // Üst halka
    canvas.drawOval(Rect.fromCenter(
        center: const Offset(-10, -8), width: 14, height: 18), paint);
    // Alt halka
    canvas.drawOval(Rect.fromCenter(
        center: const Offset(-10, 8), width: 14, height: 18), paint);
    // Pivot noktası
    canvas.drawCircle(Offset.zero, 2.5, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;

    canvas.restore();
  }

  void _drawComb(Canvas canvas, Paint paint, Offset center, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    const w = 50.0;
    const h = 8.0;
    const toothH = 18.0;
    const toothCount = 9;
    const toothSpacing = w / toothCount;

    // Tarak gövdesi
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(-w / 2, -h / 2, w, h), const Radius.circular(3)),
      paint,
    );
    // Dişler
    for (int i = 0; i < toothCount; i++) {
      final x = -w / 2 + toothSpacing / 2 + i * toothSpacing;
      canvas.drawLine(Offset(x, h / 2), Offset(x, h / 2 + toothH), paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}
