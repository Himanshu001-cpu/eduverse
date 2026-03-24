import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/gradient_text.dart';

class HeroSection extends StatelessWidget {
  final VoidCallback? onStartLearning;
  final VoidCallback? onWatchDemo;

  const HeroSection({super.key, this.onStartLearning, this.onWatchDemo});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Background Blobs
        Positioned(
          top: -100,
          left: -100,
          child:
              Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34d399).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scaleXY(
                    begin: 1.0,
                    end: 1.2,
                    duration: 4.seconds,
                    curve: Curves.easeInOut,
                  ),
        ),
        Positioned(
          top: 100,
          right: -50,
          child:
              Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2dd4bf).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scaleXY(
                    begin: 1.0,
                    end: 1.1,
                    duration: 5.seconds,
                    delay: 1.seconds,
                    curve: Curves.easeInOut,
                  ),
        ),

        // Grid Pattern Overlay (Simplified with CustomPaint if needed, skipping for now)
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1280),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 120),
            child: Flex(
              direction: size.width > 992 ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Content
                Expanded(
                  flex: size.width > 992 ? 1 : 0,
                  child: Column(
                    crossAxisAlignment: size.width > 992
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      // Badge
                      Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFecfdf5,
                              ).withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: const Color(0xFFd1fae5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10b981),
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                    .animate(
                                      onPlay: (controller) =>
                                          controller.repeat(),
                                    )
                                    .boxShadow(
                                      begin: BoxShadow(
                                        color: const Color(
                                          0xFF10b981,
                                        ).withValues(alpha: 0.5),
                                        blurRadius: 0,
                                        spreadRadius: 0,
                                      ),
                                      end: BoxShadow(
                                        color: const Color(
                                          0xFF10b981,
                                        ).withValues(alpha: 0),
                                        blurRadius: 10,
                                        spreadRadius: 4,
                                      ),
                                      duration: 1.5.seconds,
                                    ),
                                const SizedBox(width: 10),
                                Text(
                                  '#1 AI-Powered Learning Platform',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF047857),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 32),

                      // Heading
                      RichText(
                            textAlign: size.width > 992
                                ? TextAlign.start
                                : TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                fontSize: size.width > 768 ? 72 : 48,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0f172a),
                                height: 1.1,
                              ),
                              children: [
                                const TextSpan(text: 'Master every '),
                                WidgetSpan(
                                  child: GradientText(
                                    'Exam',
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF059669),
                                        Color(0xFF10b981),
                                      ],
                                    ),
                                    style: GoogleFonts.outfit(
                                      fontSize: size.width > 768 ? 72 : 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const TextSpan(text: '\nwith '),
                                WidgetSpan(
                                  child: GradientText(
                                    'AI',
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF059669),
                                        Color(0xFF10b981),
                                      ],
                                    ),
                                    style: GoogleFonts.outfit(
                                      fontSize: size.width > 768 ? 72 : 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 24),

                      Text(
                        'Personalized learning paths, smart mock tests, and real-time analytics. Crack UPSC, SSC, Banking & more with 3x higher success rate.',
                        textAlign: size.width > 992
                            ? TextAlign.start
                            : TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          color: const Color(0xFF64748b),
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 48),

                      // Buttons
                      Flex(
                            direction: size.width > 480
                                ? Axis.horizontal
                                : Axis.vertical,
                            mainAxisAlignment: size.width > 992
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
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
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: onStartLearning ?? () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
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
                                          fontSize: 16,
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
                              SizedBox(
                                width: size.width > 480 ? 16 : 0,
                                height: size.width > 480 ? 0 : 16,
                              ),
                              OutlinedButton(
                                onPressed: onWatchDemo ?? () {},
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFe2e8f0),
                                    width: 2,
                                  ),
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFd1fae5),
                                            Color(0xFFccfbf1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        LucideIcons.play,
                                        color: Color(0xFF059669),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Watch Demo',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF334155),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(delay: 600.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 48),
                      // Social Proof placement could go here
                    ],
                  ),
                ),

                if (size.width > 992) ...[
                  const SizedBox(width: 64),
                  // Right Content (Dashboard Mockup)
                  Expanded(
                    child:
                        Center(
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 40,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'DASHBOARD',
                                              style: GoogleFonts.inter(
                                                color: Colors.grey.shade400,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Your Progress',
                                              style: GoogleFonts.outfit(
                                                color: Colors.black,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFf7fee7),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                LucideIcons.trendingUp,
                                                size: 14,
                                                color: Color(0xFF65a30d),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '+12%',
                                                style: GoogleFonts.inter(
                                                  color: const Color(
                                                    0xFF65a30d,
                                                  ),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    // Simple Circular Progress
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: Stack(
                                            children: [
                                              const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      value: 1,
                                                      strokeWidth: 8,
                                                      color: Color(0xFFf1f5f9),
                                                    ),
                                              ),
                                              const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      value: 0.92,
                                                      strokeWidth: 8,
                                                      color: Color(0xFF10b981),
                                                      strokeCap:
                                                          StrokeCap.round,
                                                    ),
                                              ),
                                              Center(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '92%',
                                                      style: GoogleFonts.outfit(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 24,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Accuracy',
                                                      style: GoogleFonts.inter(
                                                        color: Colors.grey,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 32),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              _buildStatBar(
                                                'Questions Solved',
                                                '1,240',
                                                0.8,
                                                const Color(0xFF10b981),
                                              ),
                                              const SizedBox(height: 16),
                                              _buildStatBar(
                                                'Tests Completed',
                                                '48',
                                                0.6,
                                                const Color(0xFF3b82f6),
                                              ),
                                              const SizedBox(height: 16),
                                              _buildStatBar(
                                                'Study Hours',
                                                '320h',
                                                0.85,
                                                const Color(0xFFf97316),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 400.ms)
                            .slideX(begin: 0.2, end: 0)
                            .shimmer(duration: 2.seconds, delay: 1.seconds),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBar(
    String label,
    String value,
    double percent,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(100),
          ),
          child:
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percent,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ).animate().scaleXY(
                begin: 0,
                end: 1,
                duration: 1.seconds,
                curve: Curves.easeOut,
                alignment: Alignment.centerLeft,
              ),
        ),
      ],
    );
  }
}
