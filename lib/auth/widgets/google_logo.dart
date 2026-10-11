import 'package:flutter/material.dart';

/// Renders the official multi-colored Google 'G' icon using a high-precision CustomPainter.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Paint blue right curve
    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final pathBlue = Path()
      ..moveTo(w, h * 0.5)
      ..arcToPoint(Offset(w * 0.85, h * 0.8), radius: Radius.circular(w * 0.45))
      ..lineTo(w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(pathBlue, paintBlue);

    // Paint green bottom
    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final pathGreen = Path()
      ..moveTo(w * 0.85, h * 0.8)
      ..arcToPoint(Offset(w * 0.2, h * 0.8), radius: Radius.circular(w * 0.45))
      ..lineTo(w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(pathGreen, paintGreen);

    // Paint yellow left
    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final pathYellow = Path()
      ..moveTo(w * 0.2, h * 0.8)
      ..arcToPoint(Offset(w * 0.2, h * 0.2), radius: Radius.circular(w * 0.45))
      ..lineTo(w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(pathYellow, paintYellow);

    // Paint red top
    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final pathRed = Path()
      ..moveTo(w * 0.2, h * 0.2)
      ..arcToPoint(Offset(w * 0.85, h * 0.2), radius: Radius.circular(w * 0.45))
      ..lineTo(w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(pathRed, paintRed);

    // Cutout center
    final paintWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.28, paintWhite);

    // Right arm bar of Google 'G'
    final paintBar = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w * 0.48, h * 0.38, w * 0.5, h * 0.24), paintBar);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
