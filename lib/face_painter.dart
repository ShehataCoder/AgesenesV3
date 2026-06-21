import 'package:flutter/material.dart';

class FaceBox {
  final Rect rect;
  final String gender;

  FaceBox({required this.rect, required this.gender});
}

class FacePainter extends CustomPainter {
  final List<FaceBox> faceBoxes;

  FacePainter(this.faceBoxes);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF2962FF); // Blue

    for (final faceBox in faceBoxes) {
      // Draw bounding box
      canvas.drawRect(faceBox.rect, paint);

      // Draw gender label
      _drawLabel(canvas, faceBox);
    }
  }

  void _drawLabel(Canvas canvas, FaceBox faceBox) {
    final textSpan = TextSpan(
      text: faceBox.gender,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final double textWidth = textPainter.width;
    final double textHeight = textPainter.height;

    // Position above the box
    final double x = faceBox.rect.left + (faceBox.rect.width - textWidth) / 2;
    final double y = faceBox.rect.top - textHeight - 4;

    // Draw background rectangle for text
    final backgroundRect = Rect.fromLTWH(
      x - 4,
      y - 2,
      textWidth + 8,
      textHeight + 4,
    );

    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(4)),
      backgroundPaint,
    );

    // Draw text
    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faceBoxes != faceBoxes;
  }
}
