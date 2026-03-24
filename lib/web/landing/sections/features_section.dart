import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/gradient_text.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Section Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFecfdf5),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFFd1fae5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.lightbulb,
                      size: 16,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Why Eduverse?',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF059669),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),

              const SizedBox(height: 24),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0f172a),
                    height: 1.1,
                  ),
                  children: [
                    const TextSpan(text: 'Everything you need to '),
                    WidgetSpan(
                      child: GradientText(
                        'ace your exam',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10b981)],
                        ),
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 24),

              Text(
                'We combine cutting-edge AI technology with expert-curated content to\ngive you an unfair competitive advantage.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: const Color(0xFF64748b),
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 80),

              // Features Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: _features.map((feature) {
                      return _FeatureCard(feature: feature);
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

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
  final Color bgLight;

  _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.bgLight,
  });
}

final _features = [
  _FeatureData(
    icon: LucideIcons.brain,
    title: 'AI Personalized Learning',
    description:
        'Adaptive study plans that evolve with your performance, focusing on what you need most.',
    gradient: [const Color(0xFF10b981), const Color(0xFF0d9488)],
    bgLight: const Color(0xFFecfdf5),
  ),
  _FeatureData(
    icon: LucideIcons.fileCheck,
    title: 'Smart Mock Tests',
    description:
        'Exam-like environment with instant AI analysis and national ranking predictions.',
    gradient: [const Color(0xFF3b82f6), const Color(0xFF06b6d4)],
    bgLight: const Color(0xFFeff6ff),
  ),
  _FeatureData(
    icon: LucideIcons.globe,
    title: 'Daily Current Affairs',
    description:
        'Curated news, editorials, and PIB summaries mapped to your exam syllabus daily.',
    gradient: [const Color(0xFF84cc16), const Color(0xFF16a34a)],
    bgLight: const Color(0xFFf7fee7),
  ),
  _FeatureData(
    icon: LucideIcons.timer,
    title: 'Speed Quizzes',
    description:
        'Short topic-wise timed quizzes designed to boost accuracy and speed under pressure.',
    gradient: [const Color(0xFFf59e0b), const Color(0xFFea580c)],
    bgLight: const Color(0xFFfffbeb),
  ),
  _FeatureData(
    icon: LucideIcons.barChart3,
    title: 'Performance Analytics',
    description:
        'Deep insights into your strengths, weaknesses, and progress with visual dashboards.',
    gradient: [const Color(0xFFf43f5e), const Color(0xFFdb2777)],
    bgLight: const Color(0xFFfff1f2),
  ),
  _FeatureData(
    icon: LucideIcons.lightbulb,
    title: 'Smart Revision',
    description:
        'Spaced repetition and AI-powered revision schedules so you never forget what you learn.',
    gradient: [const Color(0xFF06b6d4), const Color(0xFF0ea5e9)],
    bgLight: const Color(0xFFecfeff),
  ),
];

class _FeatureCard extends StatefulWidget {
  final _FeatureData feature;

  const _FeatureCard({required this.feature});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 380,
        height: 320,
        transform: Matrix4.translationValues(0.0, _isHovered ? -8.0 : 0.0, 0.0),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered
                ? widget.feature.gradient[0].withValues(alpha: 0.3)
                : const Color(0xFFf1f5f9),
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.feature.gradient[0].withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: _isHovered ? 40 : 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Hover Glow Corner
            Positioned(
              right: -50,
              bottom: -50,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _isHovered ? 1.0 : 0.0,
                child:
                    Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: widget.feature.bgLight,
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(target: _isHovered ? 1 : 0)
                        .blur(
                          begin: const Offset(0, 0),
                          end: const Offset(50, 50),
                        ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.feature.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.feature.icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    )
                    .animate(target: _isHovered ? 1 : 0)
                    .scale(end: const Offset(1.1, 1.1))
                    .rotate(end: 0.05),

                const SizedBox(height: 24),

                Text(
                  widget.feature.title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _isHovered
                        ? const Color(0xFF059669)
                        : const Color(0xFF0f172a),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  widget.feature.description,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF64748b),
                    height: 1.6,
                  ),
                ),
              ],
            ),

            // Arrow indicator
            Positioned(
              bottom: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isHovered ? 1.0 : 0.0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFf1f5f9),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
