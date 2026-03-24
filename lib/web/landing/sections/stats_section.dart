import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/gradient_text.dart';

class StatsSection extends StatefulWidget {
  const StatsSection({super.key});

  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasAnimated = false;

  final List<_StatData> _stats = [
    _StatData(
      label: 'Active Students',
      value: 50000,
      suffix: '+',
      formattedTarget: '50K+',
      gradient: [const Color(0xFF34d399), const Color(0xFF22c55e)],
    ),
    _StatData(
      label: 'Courses Completed',
      value: 100000,
      suffix: '+',
      formattedTarget: '100K+',
      gradient: [const Color(0xFF2dd4bf), const Color(0xFF06b6d4)],
    ),
    _StatData(
      label: 'Hours of Content',
      value: 5000,
      suffix: '+',
      formattedTarget: '5K+',
      gradient: [const Color(0xFFa3e635), const Color(0xFF22c55e)],
    ),
    _StatData(
      label: 'Success Rate',
      value: 95,
      suffix: '%',
      formattedTarget: '95%',
      gradient: [const Color(0xFFfbbf24), const Color(0xFFf97316)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    if (!_hasAnimated) {
      _hasAnimated = true;
      _controller.forward();
    }
  }

  String _formatNumber(int current, _StatData stat) {
    if (stat.value >= 1000) {
      double val = current / 1000;
      if (current >= 10000) {
        return '${val.toStringAsFixed(0)}K${stat.suffix}';
      }
      return '${val.toStringAsFixed(1)}K${stat.suffix}';
    }
    return '$current${stat.suffix}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _startAnimation();
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Trigger animation when this section becomes visible
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startAnimation();
          });

          return Stack(
            children: [
              // Dark background
              Positioned.fill(child: Container(color: const Color(0xFF0f172a))),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF064e3b).withValues(alpha: 0.5),
                        const Color(0xFF0f172a),
                        const Color(0xFF134e4a).withValues(alpha: 0.5),
                      ],
                    ),
                  ),
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
                        const Color(0xFF10b981).withValues(alpha: 0.3),
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
                        const Color(0xFF14b8a6).withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Glow blobs
              Positioned(
                top: 80,
                left: size.width * 0.2,
                child: Container(
                  width: 256,
                  height: 256,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: 80,
                right: size.width * 0.2,
                child: Container(
                  width: 256,
                  height: 256,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0d9488).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 96,
                  horizontal: 24,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      children: [
                        // Header
                        Column(
                              children: [
                                Text(
                                  'Trusted by learners ',
                                  style: GoogleFonts.outfit(
                                    fontSize: size.width > 768 ? 36 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                GradientText(
                                  'everywhere',
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF34d399),
                                      Color(0xFF2dd4bf),
                                    ],
                                  ),
                                  style: GoogleFonts.outfit(
                                    fontSize: size.width > 768 ? 36 : 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Numbers that speak for themselves',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    color: const Color(0xFF94a3b8),
                                  ),
                                ),
                              ],
                            )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.15, end: 0),

                        const SizedBox(height: 64),

                        // Stats grid
                        Wrap(
                          spacing: 32,
                          runSpacing: 32,
                          alignment: WrapAlignment.center,
                          children: _stats.asMap().entries.map((entry) {
                            final index = entry.key;
                            final stat = entry.value;
                            final currentValue =
                                (_controller.value * stat.value).toInt();
                            final displayText = _formatNumber(
                              currentValue,
                              stat,
                            );

                            return SizedBox(
                                  width: size.width > 768
                                      ? (size.width > 1200 ? 260 : 200)
                                      : (size.width - 80) / 2,
                                  child: Column(
                                    children: [
                                      ShaderMask(
                                        shaderCallback: (bounds) =>
                                            LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: stat.gradient,
                                            ).createShader(bounds),
                                        child: Text(
                                          displayText,
                                          style: GoogleFonts.outfit(
                                            fontSize: size.width > 768
                                                ? 56
                                                : 40,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: -2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        stat.label.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF94a3b8),
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _AnimatedBar(
                                        gradient: stat.gradient,
                                        delay: index * 100,
                                      ),
                                    ],
                                  ),
                                )
                                .animate()
                                .fadeIn(
                                  delay: (index * 100).ms,
                                  duration: 500.ms,
                                )
                                .slideY(begin: 0.2, end: 0);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedBar extends StatefulWidget {
  final List<Color> gradient;
  final int delay;

  const _AnimatedBar({required this.gradient, required this.delay});

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: _isHovered ? 80 : 48,
        height: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: LinearGradient(colors: widget.gradient),
          color: widget.gradient[0].withValues(alpha: _isHovered ? 1.0 : 0.4),
        ),
      ),
    );
  }
}

class _StatData {
  final String label;
  final int value;
  final String suffix;
  final String formattedTarget;
  final List<Color> gradient;

  _StatData({
    required this.label,
    required this.value,
    required this.suffix,
    required this.formattedTarget,
    required this.gradient,
  });
}
