import 'package:flutter/material.dart';
import '../../../auth/register_page.dart';
import '../theme/academic_futurist_theme.dart';

class CtaSection extends StatelessWidget {
  final VoidCallback? onJoin;

  const CtaSection({super.key, this.onJoin});

  void _navigateToRegister(BuildContext context) {
    if (onJoin != null) {
      onJoin!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RegisterPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Container(
      width: double.infinity,
      color: EduverseTheme.deepNavy,
      padding: const EdgeInsets.symmetric(vertical: 96),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Geometric Grid Pattern Background
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPatternPainter(
                lineColor: Colors.white.withValues(alpha: 0.05),
                gridSize: 40.0,
              ),
            ),
          ),

          // Glowing Radial Ambient Accent
          Positioned(
            child: Container(
              width: 500,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EduverseTheme.primaryContainer.withValues(alpha: 0.15),
              ),
            ),
          ),

          // Centered Content
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? EduverseTheme.marginDesktop : EduverseTheme.marginMobile,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Ready to Shape Your Future?',
                    textAlign: TextAlign.center,
                    style: isDesktop
                        ? EduverseTheme.displayLg(color: Colors.white)
                        : EduverseTheme.displayLgMobile(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Text(
                      'Join thousands of ambitious learners in The Eduverse. Start your journey towards academic excellence today.',
                      textAlign: TextAlign.center,
                      style: EduverseTheme.bodyLg(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _GoldCtaButton(
                    onPressed: () => _navigateToRegister(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldCtaButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _GoldCtaButton({required this.onPressed});

  @override
  State<_GoldCtaButton> createState() => _GoldCtaButtonState();
}

class _GoldCtaButtonState extends State<_GoldCtaButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: _isHovered
              ? EduverseTheme.tertiaryFixedDim
              : EduverseTheme.tertiaryFixed,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: EduverseTheme.tertiaryFixed.withValues(alpha: _isHovered ? 0.45 : 0.25),
              blurRadius: _isHovered ? 28 : 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Join The Eduverse Today',
                    style: EduverseTheme.labelLg(color: EduverseTheme.onTertiaryFixed).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: EduverseTheme.onTertiaryFixed,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  final Color lineColor;
  final double gridSize;

  _GridPatternPainter({required this.lineColor, required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.6;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
