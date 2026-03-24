import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/gradient_text.dart';

class ExamCategoriesSection extends StatelessWidget {
  const ExamCategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 112, horizontal: 24),
      color: const Color(0xFFf8fafc).withValues(alpha: 0.5),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Flex(
                direction: size.width > 768 ? Axis.horizontal : Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: size.width > 768
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFecfdf5),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0xFFd1fae5)),
                        ),
                        child: Text(
                          '🎯 Exam Categories',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF059669),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.outfit(
                            fontSize: size.width > 768 ? 48 : 36,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0f172a),
                            height: 1.1,
                          ),
                          children: [
                            const TextSpan(text: 'Choose your path to '),
                            WidgetSpan(
                              child: GradientText(
                                'Success',
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF059669),
                                    Color(0xFF10b981),
                                  ],
                                ),
                                style: GoogleFonts.outfit(
                                  fontSize: size.width > 768 ? 48 : 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (size.width > 768)
                    TextButton(
                      onPressed: () {},
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All Categories',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF059669),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '→',
                            style: TextStyle(color: Color(0xFF059669)),
                          ),
                        ],
                      ),
                    ),
                ],
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),

              const SizedBox(height: 48),

              // Category Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 900
                      ? 6
                      : constraints.maxWidth > 600
                      ? 3
                      : 2;
                  final cardWidth =
                      (constraints.maxWidth - (crossAxisCount - 1) * 20) /
                      crossAxisCount;

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: _categories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final cat = entry.value;
                      return _CategoryCard(
                        category: cat,
                        width: cardWidth,
                        delay: index * 80,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final _CategoryData category;
  final double width;
  final int delay;

  const _CategoryCard({
    required this.category,
    required this.width,
    required this.delay,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: widget.width,
            transform: Matrix4.translationValues(
              0.0,
              _isHovered ? -8.0 : 0.0,
              0.0,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isHovered
                    ? widget.category.gradient[0].withValues(alpha: 0.3)
                    : const Color(0xFFf1f5f9),
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? widget.category.glowColor.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: _isHovered ? 24 : 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 64,
                  height: 64,
                  transform: Matrix4.diagonal3Values(
                    _isHovered ? 1.1 : 1.0,
                    _isHovered ? 1.1 : 1.0,
                    1.0,
                  )..rotateZ(_isHovered ? 0.1 : 0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.category.gradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: widget.category.gradient[0].withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.category.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.category.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0f172a),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.category.count,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94a3b8),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: widget.delay.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          delay: widget.delay.ms,
        );
  }
}

class _CategoryData {
  final String title;
  final String count;
  final IconData icon;
  final List<Color> gradient;
  final Color glowColor;

  _CategoryData({
    required this.title,
    required this.count,
    required this.icon,
    required this.gradient,
    required this.glowColor,
  });
}

final _categories = [
  _CategoryData(
    title: 'UPSC CSE',
    count: '12 Courses',
    icon: LucideIcons.landmark,
    gradient: [const Color(0xFF10b981), const Color(0xFF0d9488)],
    glowColor: const Color(0xFF10b981),
  ),
  _CategoryData(
    title: 'SSC Exams',
    count: '25 Courses',
    icon: LucideIcons.briefcase,
    gradient: [const Color(0xFF3b82f6), const Color(0xFF06b6d4)],
    glowColor: const Color(0xFF3b82f6),
  ),
  _CategoryData(
    title: 'Banking',
    count: '18 Courses',
    icon: LucideIcons.graduationCap,
    gradient: [const Color(0xFF8b5cf6), const Color(0xFF7c3aed)],
    glowColor: const Color(0xFF8b5cf6),
  ),
  _CategoryData(
    title: 'Railways',
    count: '10 Courses',
    icon: LucideIcons.train,
    gradient: [const Color(0xFFf59e0b), const Color(0xFFea580c)],
    glowColor: const Color(0xFFf59e0b),
  ),
  _CategoryData(
    title: 'Defence',
    count: '15 Courses',
    icon: LucideIcons.shield,
    gradient: [const Color(0xFFef4444), const Color(0xFFf43f5e)],
    glowColor: const Color(0xFFef4444),
  ),
  _CategoryData(
    title: 'State Exams',
    count: '30+ Courses',
    icon: LucideIcons.bookOpen,
    gradient: [const Color(0xFF06b6d4), const Color(0xFF0ea5e9)],
    glowColor: const Color(0xFF06b6d4),
  ),
];
