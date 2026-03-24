import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CtaSection extends StatelessWidget {
  const CtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Dark background
        Positioned.fill(child: Container(color: const Color(0xFF020617))),
        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF064e3b).withValues(alpha: 0.7),
                  const Color(0xFF020617),
                  const Color(0xFF134e4a).withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),
        // Animated blobs
        Positioned(
          top: 0,
          left: size.width * 0.2,
          child:
              Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scaleXY(
                    begin: 1.0,
                    end: 1.2,
                    duration: 7.seconds,
                    curve: Curves.easeInOut,
                  ),
        ),
        Positioned(
          bottom: 0,
          right: size.width * 0.2,
          child:
              Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0d9488).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scaleXY(
                    begin: 1.0,
                    end: 1.15,
                    duration: 8.seconds,
                    delay: 2.seconds,
                    curve: Curves.easeInOut,
                  ),
        ),
        // Top line
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF10b981).withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Bottom line
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF14b8a6).withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 112, horizontal: 24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              child:
                  Column(
                        children: [
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10b981,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: const Color(
                                  0xFF10b981,
                                ).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.sparkles,
                                  size: 16,
                                  color: Color(0xFF6ee7b7),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Limited Time: 50% Off All Courses',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF6ee7b7),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Heading
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                fontSize: size.width > 768
                                    ? 56
                                    : size.width > 480
                                    ? 44
                                    : 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.15,
                              ),
                              children: [
                                const TextSpan(text: 'Ready to start your\n'),
                                WidgetSpan(
                                  child: ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                          colors: [
                                            Color(0xFF34d399),
                                            Color(0xFF2dd4bf),
                                            Colors.white,
                                          ],
                                        ).createShader(bounds),
                                    child: Text(
                                      'Success Story?',
                                      style: GoogleFonts.outfit(
                                        fontSize: size.width > 768
                                            ? 56
                                            : size.width > 480
                                            ? 44
                                            : 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: 640,
                            child: Text(
                              'Join 50,000+ students already learning smarter with AI. Get unlimited access to mock tests, video lectures, and personalized guidance.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                color: const Color(0xFF94a3b8),
                                height: 1.6,
                              ),
                            ),
                          ),

                          const SizedBox(height: 48),

                          // CTA Buttons
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              // Primary button
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF059669),
                                      Color(0xFF047857),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF10b981,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Start Learning Free',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(
                                        LucideIcons.arrowRight,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Secondary button
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFF334155),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.calendar,
                                      size: 20,
                                      color: Color(0xFF34d399),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Book a Live Demo',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Trust indicators
                          Wrap(
                            spacing: 24,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _trustItem('✓  No credit card'),
                              _trustItem('✓  7-day free trial'),
                              _trustItem('✓  Cancel anytime'),
                            ],
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1),
                      ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _trustItem(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748b)),
    );
  }
}
