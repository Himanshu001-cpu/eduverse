import 'package:flutter/material.dart';
import '../theme/academic_futurist_theme.dart';

class BentoAdvantageSection extends StatelessWidget {
  const BentoAdvantageSection({super.key});

  static const String _certificateImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuB4ch6JDRdMgwkW8MGCtU8O59spRfP_jnzIfSJAoOF-r-WFeZWQKF3OpxlQpc1SCae6Zq0IIqZWy3FfPrxOuI71iuizQsXi13FvgH7WHHM_H-aH7Tv7tTSrOt0SCUB8pydHsWRITPgKU4vGMyAnkDCGhcVBP9fxMgSEuIrZJkJLgUgL8GxvBTBQmn2p2RimO46BTzRm9Uu3R2XpCQ1hodYWsQNiG1ukkaSm35WcWMPLmrkixqjmcBdg';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Container(
      width: double.infinity,
      color: EduverseTheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: EduverseTheme.sectionGap),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: EduverseTheme.containerMax),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? EduverseTheme.marginDesktop : EduverseTheme.marginMobile,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Section Header
              Text(
                'THE EDUVERSE ADVANTAGE',
                style: EduverseTheme.labelSm(
                  color: EduverseTheme.primary,
                  letterSpacing: 2.0,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Designed for the Modern Learner',
                textAlign: TextAlign.center,
                style: EduverseTheme.headlineLg(color: EduverseTheme.onSurface),
              ),
              const SizedBox(height: 56),

              // Bento Layout
              if (isDesktop)
                SizedBox(
                  height: 560,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Large Card (Left 2/3)
                      Expanded(
                        flex: 2,
                        child: _LargeBentoCard(imageUrl: _certificateImageUrl),
                      ),
                      const SizedBox(width: 24),
                      // Two Stacked Cards (Right 1/3)
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: const [
                            Expanded(
                              child: _SmallBentoCard(
                                title: 'Live Classes with Timetable',
                                description:
                                    'Stay on track with our structured live classes and integrated schedule management.',
                                icon: Icons.laptop_mac,
                                watermarkIcon: Icons.schedule,
                                accentColor: EduverseTheme.tertiaryContainer,
                              ),
                            ),
                            SizedBox(height: 24),
                            Expanded(
                              child: _SmallBentoCard(
                                title: 'Test Series with Analytics',
                                description:
                                    'Evaluate your performance with comprehensive tests and detailed analytical feedback.',
                                icon: Icons.school,
                                watermarkIcon: Icons.psychology,
                                accentColor: EduverseTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    _LargeBentoCard(imageUrl: _certificateImageUrl),
                    const SizedBox(height: 24),
                    const _SmallBentoCard(
                      title: 'Live Classes with Timetable',
                      description:
                          'Stay on track with our structured live classes and integrated schedule management.',
                      icon: Icons.laptop_mac,
                      watermarkIcon: Icons.schedule,
                      accentColor: EduverseTheme.tertiaryContainer,
                    ),
                    const SizedBox(height: 24),
                    const _SmallBentoCard(
                      title: 'Test Series with Analytics',
                      description:
                          'Evaluate your performance with comprehensive tests and detailed analytical feedback.',
                      icon: Icons.school,
                      watermarkIcon: Icons.psychology,
                      accentColor: EduverseTheme.secondary,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeBentoCard extends StatefulWidget {
  final String imageUrl;

  const _LargeBentoCard({required this.imageUrl});

  @override
  State<_LargeBentoCard> createState() => _LargeBentoCardState();
}

class _LargeBentoCardState extends State<_LargeBentoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: EduverseTheme.primary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: EduverseTheme.primary.withValues(alpha: _isHovered ? 0.35 : 0.20),
              blurRadius: _isHovered ? 32 : 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Ambient Glowing Orb
              Positioned(
                right: -60,
                bottom: -60,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: _isHovered ? 360 : 300,
                  height: _isHovered ? 360 : 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EduverseTheme.primaryContainer.withValues(alpha: 0.6),
                  ),
                ),
              ),

              // Content Padding
              Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.public,
                        color: EduverseTheme.onPrimary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Secure PDF Notes/DPPs',
                      style: EduverseTheme.headlineLg(color: EduverseTheme.onPrimary),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Text(
                        'Access high-quality study materials and Daily Practice Problems securely within the app. Our curriculum is co-created with top educators.',
                        style: EduverseTheme.bodyLg(
                          color: EduverseTheme.onPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 190,
                        width: double.infinity,
                        child: Image.network(
                          widget.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallBentoCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final IconData watermarkIcon;
  final Color accentColor;

  const _SmallBentoCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.watermarkIcon,
    required this.accentColor,
  });

  @override
  State<_SmallBentoCard> createState() => _SmallBentoCardState();
}

class _SmallBentoCardState extends State<_SmallBentoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: EduverseTheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.accentColor.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 24 : 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: EduverseTheme.outlineVariant.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Large Watermark Icon
              Positioned(
                top: 16,
                right: 16,
                child: Icon(
                  widget.watermarkIcon,
                  size: 72,
                  color: widget.accentColor.withValues(alpha: 0.10),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      style: EduverseTheme.headlineMd(color: EduverseTheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      style: EduverseTheme.bodyMd(color: EduverseTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
