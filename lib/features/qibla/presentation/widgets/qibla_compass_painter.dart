import 'dart:math' as math;
import 'package:flutter/material.dart';

class QiblaCompassPainter extends CustomPainter {
  final double qiblaAngle;
  final String northLabel;
  final String eastLabel;
  final String southLabel;
  final String westLabel;
  final bool isAligned;

  QiblaCompassPainter({
    required this.qiblaAngle,
    required this.northLabel,
    required this.eastLabel,
    required this.southLabel,
    required this.westLabel,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Outer subtle gradient ring
    final outerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = isAligned
          ? const Color(0xFF10B981).withValues(alpha: 0.6)
          : const Color(0xFF003D82).withValues(alpha: 0.2);
    canvas.drawCircle(center, radius - 4, outerRingPaint);

    // Inner subtle ring
    final innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = isAligned
          ? const Color(0xFF10B981).withValues(alpha: 0.3)
          : Colors.grey.withValues(alpha: 0.25);
    canvas.drawCircle(center, radius - 28, innerRingPaint);

    // Draw degree tick marks and cardinal directions
    final tickPaint = Paint()..style = PaintingStyle.stroke;

    for (int i = 0; i < 360; i += 5) {
      final angleRad = (i - 90) * (math.pi / 180.0);
      final isMajor = i % 30 == 0;
      final isCardinal = i % 90 == 0;

      double tickLength;
      if (isCardinal) {
        tickLength = 14;
        tickPaint.strokeWidth = 2.5;
        tickPaint.color = i == 0
            ? const Color(0xFFE53935) // North is Red
            : const Color(0xFF003D82);
      } else if (isMajor) {
        tickLength = 9;
        tickPaint.strokeWidth = 1.5;
        tickPaint.color = const Color(0xFF64748B);
      } else {
        tickLength = 5;
        tickPaint.strokeWidth = 1.0;
        tickPaint.color = const Color(0xFFCBD5E1);
      }

      final outerX = center.dx + (radius - 8) * math.cos(angleRad);
      final outerY = center.dy + (radius - 8) * math.sin(angleRad);
      final innerX = center.dx + (radius - 8 - tickLength) * math.cos(angleRad);
      final innerY = center.dy + (radius - 8 - tickLength) * math.sin(angleRad);

      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        tickPaint,
      );

      // Draw Cardinal and Major Degree text
      if (isCardinal) {
        String label = '';
        Color textColor = const Color(0xFF1E293B);
        if (i == 0) {
          label = northLabel;
          textColor = const Color(0xFFE53935);
        } else if (i == 90) {
          label = eastLabel;
        } else if (i == 180) {
          label = southLabel;
        } else if (i == 270) {
          label = westLabel;
        }

        final textSpan = TextSpan(
          text: label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final textRadius = radius - 36;
        final textX = center.dx + textRadius * math.cos(angleRad) - (textPainter.width / 2);
        final textY = center.dy + textRadius * math.sin(angleRad) - (textPainter.height / 2);
        textPainter.paint(canvas, Offset(textX, textY));
      } else if (isMajor) {
        final textSpan = TextSpan(
          text: '$i°',
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final textRadius = radius - 24;
        final textX = center.dx + textRadius * math.cos(angleRad) - (textPainter.width / 2);
        final textY = center.dy + textRadius * math.sin(angleRad) - (textPainter.height / 2);
        textPainter.paint(canvas, Offset(textX, textY));
      }
    }

    // Draw Kaaba Marker on the perimeter at qiblaAngle
    _drawKaabaMarker(canvas, center, radius, qiblaAngle);
  }

  void _drawKaabaMarker(Canvas canvas, Offset center, double radius, double angleDeg) {
    final angleRad = (angleDeg - 90) * (math.pi / 180.0);
    final markerRadius = radius - 12;
    final markerCenter = Offset(
      center.dx + markerRadius * math.cos(angleRad),
      center.dy + markerRadius * math.sin(angleRad),
    );

    canvas.save();
    canvas.translate(markerCenter.dx, markerCenter.dy);
    canvas.rotate(angleRad + math.pi / 2);

    // Glowing halo if aligned
    if (isAligned) {
      final glowPaint = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset.zero, 18, glowPaint);
    }

    // Marker base circle (gold/amber)
    final bgPaint = Paint()
      ..color = isAligned ? const Color(0xFF10B981) : const Color(0xFFD97706);
    canvas.drawCircle(Offset.zero, 14, bgPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white;
    canvas.drawCircle(Offset.zero, 14, borderPaint);

    // Kaaba Cube Icon
    final cubePaint = Paint()..color = const Color(0xFF18181B);
    final cubeRect = Rect.fromCenter(center: Offset.zero, width: 14, height: 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cubeRect, const Radius.circular(2)),
      cubePaint,
    );

    // Gold Kiswah band
    final goldBandPaint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawRect(
      Rect.fromLTWH(-7, -4, 14, 2.5),
      goldBandPaint,
    );

    // Kaaba golden door
    final doorPaint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawRect(
      Rect.fromLTWH(1, 1, 3, 5),
      doorPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant QiblaCompassPainter oldDelegate) {
    return oldDelegate.qiblaAngle != qiblaAngle ||
        oldDelegate.isAligned != isAligned ||
        oldDelegate.northLabel != northLabel;
  }
}

class QiblaNeedlePainter extends CustomPainter {
  final bool isAligned;

  QiblaNeedlePainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final length = size.height / 2 - 32;

    // Pointer to Kaaba (Top/Forward)
    final qiblaPathLeft = Path()
      ..moveTo(center.dx, center.dy - length)
      ..lineTo(center.dx - 8, center.dy)
      ..lineTo(center.dx, center.dy - 6)
      ..close();

    final qiblaPaintLeft = Paint()
      ..color = isAligned ? const Color(0xFF10B981) : const Color(0xFFD97706);
    canvas.drawPath(qiblaPathLeft, qiblaPaintLeft);

    final qiblaPathRight = Path()
      ..moveTo(center.dx, center.dy - length)
      ..lineTo(center.dx + 8, center.dy)
      ..lineTo(center.dx, center.dy - 6)
      ..close();

    final qiblaPaintRight = Paint()
      ..color = isAligned ? const Color(0xFF34D399) : const Color(0xFFF59E0B);
    canvas.drawPath(qiblaPathRight, qiblaPaintRight);

    // South/Back pointer (Subtle grey needle tail)
    final tailPathLeft = Path()
      ..moveTo(center.dx, center.dy + (length * 0.5))
      ..lineTo(center.dx - 6, center.dy)
      ..lineTo(center.dx, center.dy + 4)
      ..close();

    final tailPaintLeft = Paint()..color = const Color(0xFF94A3B8);
    canvas.drawPath(tailPathLeft, tailPaintLeft);

    final tailPathRight = Path()
      ..moveTo(center.dx, center.dy + (length * 0.5))
      ..lineTo(center.dx + 6, center.dy)
      ..lineTo(center.dx, center.dy + 4)
      ..close();

    final tailPaintRight = Paint()..color = const Color(0xFFCBD5E1);
    canvas.drawPath(tailPathRight, tailPaintRight);

    // Center Hub (metallic look)
    final hubShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, 14, hubShadowPaint);

    final hubOuterPaint = Paint()
      ..color = isAligned ? const Color(0xFF10B981) : const Color(0xFF003D82);
    canvas.drawCircle(center, 12, hubOuterPaint);

    final hubInnerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 6, hubInnerPaint);

    final hubCorePaint = Paint()
      ..color = isAligned ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    canvas.drawCircle(center, 3.5, hubCorePaint);
  }

  @override
  bool shouldRepaint(covariant QiblaNeedlePainter oldDelegate) {
    return oldDelegate.isAligned != isAligned;
  }
}
