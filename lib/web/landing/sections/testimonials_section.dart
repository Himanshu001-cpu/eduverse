import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/gradient_text.dart';

class TestimonialsSection extends StatefulWidget {
  const TestimonialsSection({super.key});

  @override
  State<TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<TestimonialsSection> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Background blob
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              color: const Color(0xFFecfdf5).withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 112, horizontal: 24),
          color: const Color(0xFFf8fafc).withValues(alpha: 0.5),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                children: [
                  // Header
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFfff1f2),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0xFFffe4e6)),
                        ),
                        child: Text(
                          '⭐ Student Stories',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFe11d48),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.outfit(
                            fontSize: size.width > 768 ? 48 : 36,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0f172a),
                            height: 1.1,
                          ),
                          children: [
                            const TextSpan(text: 'Loved by '),
                            WidgetSpan(
                              child: GradientText(
                                '50,000+',
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
                            const TextSpan(text: ' students'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 560,
                        child: Text(
                          'Real stories from real toppers who cracked their dream exams with Eduverse.',
                          textAlign: TextAlign.center,
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

                  // Main testimonial card
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.05),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          key: ValueKey<int>(_activeIndex),
                          padding: EdgeInsets.all(size.width > 768 ? 48 : 32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFf1f5f9)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                LucideIcons.quote,
                                size: 40,
                                color: const Color(
                                  0xFF10b981,
                                ).withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                '"${_testimonials[_activeIndex].text}"',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: size.width > 768 ? 22 : 18,
                                  color: const Color(0xFF334155),
                                  fontWeight: FontWeight.w500,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Author
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: const Color(0xFFe2e8f0),
                                    backgroundImage: NetworkImage(
                                      _testimonials[_activeIndex].avatar,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _testimonials[_activeIndex].name,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0f172a),
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        _testimonials[_activeIndex].role,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: const Color(0xFF10b981),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 1,
                                    height: 32,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    color: const Color(0xFFe2e8f0),
                                  ),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (_) => const Icon(
                                        LucideIcons.star,
                                        size: 16,
                                        color: Color(0xFFfbbf24),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Thumbnail selector
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _testimonials.asMap().entries.map((entry) {
                      final index = entry.key;
                      final t = entry.value;
                      final isActive = _activeIndex == index;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _activeIndex = index),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFF6ee7b7)
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF10b981,
                                        ).withValues(alpha: 0.15),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            transform: Matrix4.diagonal3Values(
                              isActive ? 1.05 : 1.0,
                              isActive ? 1.05 : 1.0,
                              1.0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(t.avatar),
                                ),
                                if (size.width > 600) ...[
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isActive
                                              ? const Color(0xFF059669)
                                              : const Color(0xFF334155),
                                        ),
                                      ),
                                      Text(
                                        t.role.split('—')[0].trim(),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF94a3b8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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

class _TestimonialData {
  final String name;
  final String role;
  final String avatar;
  final String text;

  _TestimonialData({
    required this.name,
    required this.role,
    required this.avatar,
    required this.text,
  });
}

final _testimonials = [
  _TestimonialData(
    name: 'Ankit Sharma',
    role: 'UPSC CSE 2024 — AIR 47',
    avatar:
        'https://ui-avatars.com/api/?name=Ankit+Sharma&background=10b981&color=fff&size=150',
    text:
        'Eduverse completely transformed my preparation. The AI-personalized study plan helped me focus on weak areas I didn\'t even know I had. Cleared UPSC in my first attempt!',
  ),
  _TestimonialData(
    name: 'Priya Patel',
    role: 'SBI PO 2024 — Selected',
    avatar:
        'https://ui-avatars.com/api/?name=Priya+Patel&background=3b82f6&color=fff&size=150',
    text:
        'The mock tests are incredibly realistic. The detailed analytics after each test showed me exactly where I was losing marks. Best decision I made was joining Eduverse.',
  ),
  _TestimonialData(
    name: 'Rohit Kumar',
    role: 'SSC CGL 2024 — Rank 12',
    avatar:
        'https://ui-avatars.com/api/?name=Rohit+Kumar&background=8b5cf6&color=fff&size=150',
    text:
        'From daily quizzes to answer writing practice, everything is so well organized. The AI doubt solver is like having a tutor available 24/7. Highly recommended!',
  ),
  _TestimonialData(
    name: 'Sneha Reddy',
    role: 'RBI Grade B — Selected',
    avatar:
        'https://ui-avatars.com/api/?name=Sneha+Reddy&background=f59e0b&color=fff&size=150',
    text:
        'The video lectures are world-class and the current affairs section saved me so much time. Eduverse is hands down the best platform for banking exam preparation.',
  ),
  _TestimonialData(
    name: 'Vikram Singh',
    role: 'NDA 2024 — Written Cleared',
    avatar:
        'https://ui-avatars.com/api/?name=Vikram+Singh&background=ef4444&color=fff&size=150',
    text:
        'The performance analytics showed me I was spending too much time on strong topics. After adjusting my strategy based on Eduverse insights, my scores jumped 30%.',
  ),
  _TestimonialData(
    name: 'Meera Joshi',
    role: 'UPPSC 2024 — Rank 8',
    avatar:
        'https://ui-avatars.com/api/?name=Meera+Joshi&background=06b6d4&color=fff&size=150',
    text:
        'I switched from traditional coaching to Eduverse mid-preparation and it was the best decision. The AI revision scheduler ensured I never forgot what I studied.',
  ),
];
