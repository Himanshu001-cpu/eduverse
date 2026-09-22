import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/academic_futurist_theme.dart';

class HeroSection extends StatelessWidget {
  final VoidCallback? onExploreCourses;
  final VoidCallback? onWatchVideo;

  const HeroSection({
    super.key,
    this.onExploreCourses,
    this.onWatchVideo,
  });

  static const String _heroImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCLbF4QxKNoSv_-eLj8gKQxBCq40b0Zos7vAP8IUVbk-vOqimonG5RCStY9o6EQx2lC_C2E8dQn8KT8uWEGMpAb4qTEg2-vlUIbEXC8PuzkVr0l2nwCcM_ZSuLT72Rnc8uUbDH1FycciQOkUNqj7vFqTTrntssOjEsugVQa6jwGtA5aF5hPEdHdhbfcWJtbSGxNOiVqyi8X_n3HLbASsr4e7C4kqzcXZOsaM4Rxa-2kK5N5VVs5KAtI';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 740),
      color: EduverseTheme.surface,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Atmospheric Library Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.network(
                _heroImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

          // Soft Ambient Radial & Linear Gradient Overlays
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    EduverseTheme.surface.withValues(alpha: 0.85),
                    EduverseTheme.surface.withValues(alpha: 0.50),
                    EduverseTheme.surface,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Subtle Emerald Glow
          Positioned(
            top: 60,
            child: Container(
              width: 500,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EduverseTheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Main Centered Content
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: EduverseTheme.containerMax),
              padding: EdgeInsets.only(
                top: 130,
                bottom: 120,
                left: isDesktop ? EduverseTheme.marginDesktop : EduverseTheme.marginMobile,
                right: isDesktop ? EduverseTheme.marginDesktop : EduverseTheme.marginMobile,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Headline
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: isDesktop
                          ? EduverseTheme.displayLg(color: EduverseTheme.onSurface)
                          : EduverseTheme.displayLgMobile(color: EduverseTheme.onSurface),
                      children: [
                        const TextSpan(text: 'The Future of Education\n'),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Text(
                                'is Here',
                                style: (isDesktop
                                        ? EduverseTheme.displayLg(color: EduverseTheme.primary)
                                        : EduverseTheme.displayLgMobile(color: EduverseTheme.primary))
                                    .copyWith(
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Positioned(
                                bottom: -2,
                                left: 0,
                                right: 0,
                                child: CustomPaint(
                                  size: const Size(120, 10),
                                  painter: _CurvedUnderlinePainter(
                                    color: EduverseTheme.tertiaryFixedDim,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subtitle
                  Container(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Text(
                      'Comprehensive ed-tech platform for competitive exam preparation. Empowering the next generation of leaders with world-class education.',
                      textAlign: TextAlign.center,
                      style: isDesktop
                          ? EduverseTheme.bodyLg(color: EduverseTheme.onSurfaceVariant)
                          : EduverseTheme.bodyMd(color: EduverseTheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // CTAs
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      // Primary Button: Explore Courses
                      _PillButton(
                        label: 'Explore Courses',
                        backgroundColor: EduverseTheme.primary,
                        foregroundColor: EduverseTheme.onPrimary,
                        onPressed: onExploreCourses,
                        elevation: 4,
                      ),

                      // Secondary Button: Watch Video
                      _PillButton(
                        label: 'Watch Video',
                        icon: Icons.play_circle_outline,
                        backgroundColor: EduverseTheme.surface,
                        foregroundColor: EduverseTheme.primary,
                        borderColor: EduverseTheme.primaryContainer,
                        onPressed: onWatchVideo,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bouncing Scroll Indicator
          Positioned(
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SCROLL',
                  style: EduverseTheme.labelSm(
                    color: EduverseTheme.onSurfaceVariant.withValues(alpha: 0.7),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_downward,
                  size: 18,
                  color: EduverseTheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ],
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .moveY(begin: 0, end: 8, duration: 900.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback? onPressed;
  final double elevation;

  const _PillButton({
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.onPressed,
    this.elevation = 0,
  });

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: _isHovered
              ? widget.backgroundColor.withValues(alpha: 0.92)
              : widget.backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: widget.borderColor != null
              ? Border.all(color: widget.borderColor!, width: 1.5)
              : null,
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.backgroundColor.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : (widget.elevation > 0
                  ? [
                      BoxShadow(
                        color: widget.backgroundColor.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: widget.foregroundColor, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: EduverseTheme.labelLg(color: widget.foregroundColor).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
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

class _CurvedUnderlinePainter extends CustomPainter {
  final Color color;
  _CurvedUnderlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * -0.2,
      size.width * 0.7,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.4,
      size.width,
      size.height * 0.6,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
