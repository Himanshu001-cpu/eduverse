import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/gradient_text.dart';

class ContentSection extends StatelessWidget {
  const ContentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Background blob
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              color: const Color(0xFFecfdf5).withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 112, horizontal: 24),
          color: Colors.white,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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
                          '📚 Learning Resources',
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
                            const TextSpan(text: 'What interests '),
                            WidgetSpan(
                              child: GradientText(
                                'you?',
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 560,
                        child: Text(
                          'Explore our diverse range of study materials designed for comprehensive exam preparation.',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: const Color(0xFF64748b),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn().slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 48),

                  // Content Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final colCount = constraints.maxWidth > 768 ? 4 : 2;
                      final gap = 16.0;
                      final cardWidth =
                          (constraints.maxWidth - (colCount - 1) * gap) /
                          colCount;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: _contents.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final isWide =
                              item.span == 2 && constraints.maxWidth > 768;
                          final width = isWide
                              ? cardWidth * 2 + gap
                              : cardWidth;

                          return _ContentCard(
                            item: item,
                            width: width,
                            delay: index * 60,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContentCard extends StatefulWidget {
  final _ContentData item;
  final double width;
  final int delay;

  const _ContentCard({
    required this.item,
    required this.width,
    required this.delay,
  });

  @override
  State<_ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<_ContentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: widget.width,
            height: 200,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isHovered
                    ? widget.item.gradient[0].withValues(alpha: 0.3)
                    : const Color(0xFFf1f5f9),
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? widget.item.gradient[0].withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: _isHovered ? 30 : 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 48,
                      height: 48,
                      transform: Matrix4.diagonal3Values(
                        _isHovered ? 1.1 : 1.0,
                        _isHovered ? 1.1 : 1.0,
                        1.0,
                      )..rotateZ(_isHovered ? 0.1 : 0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.item.gradient,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: widget.item.gradient[0].withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.item.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.title,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isHovered
                                ? const Color(0xFF059669)
                                : const Color(0xFF0f172a),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF94a3b8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Hover glow corner
                Positioned(
                  bottom: -64,
                  right: -64,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 700),
                    opacity: _isHovered ? 0.06 : 0,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 700),
                      scale: _isHovered ? 1.5 : 1.0,
                      child: Container(
                        width: 192,
                        height: 192,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: widget.item.gradient,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: widget.delay.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          delay: widget.delay.ms,
        );
  }
}

class _ContentData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final int span;

  _ContentData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    this.span = 1,
  });
}

final _contents = [
  _ContentData(
    title: 'Current Affairs',
    description: 'Daily curated news & editorials',
    icon: LucideIcons.newspaper,
    gradient: [const Color(0xFF0ea5e9), const Color(0xFF2563eb)],
    span: 2,
  ),
  _ContentData(
    title: 'Video Lectures',
    description: '1000+ hours by top faculty',
    icon: LucideIcons.video,
    gradient: [const Color(0xFF10b981), const Color(0xFF16a34a)],
  ),
  _ContentData(
    title: 'Daily Quiz',
    description: 'Test yourself every day',
    icon: LucideIcons.brain,
    gradient: [const Color(0xFFf59e0b), const Color(0xFFea580c)],
  ),
  _ContentData(
    title: 'Answer Writing',
    description: 'Practice with AI evaluation',
    icon: LucideIcons.penTool,
    gradient: [const Color(0xFFf43f5e), const Color(0xFFdb2777)],
    span: 2,
  ),
  _ContentData(
    title: 'Previous Papers',
    description: '20+ years solved PYQs',
    icon: LucideIcons.bookOpen,
    gradient: [const Color(0xFF14b8a6), const Color(0xFF06b6d4)],
  ),
  _ContentData(
    title: 'Articles & Notes',
    description: 'Expert study material',
    icon: LucideIcons.trophy,
    gradient: [const Color(0xFF8b5cf6), const Color(0xFF7c3aed)],
  ),
];
