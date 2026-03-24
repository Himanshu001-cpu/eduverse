import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/gradient_text.dart';
import '../../../auth/login_page.dart';
import '../../../store/screens/course_detail_page.dart';
import '../../../store/models/store_models.dart';

class TrendingCoursesSection extends StatefulWidget {
  const TrendingCoursesSection({super.key});

  @override
  State<TrendingCoursesSection> createState() => _TrendingCoursesSectionState();
}

class _TrendingCoursesSectionState extends State<TrendingCoursesSection> {
  final ScrollController _scrollController = ScrollController();

  void _scroll(double direction) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.offset + (direction * 400),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Tag styling based on course level/tags
  static const _tagStyles = {
    'beginner': (
      label: 'Beginner',
      colors: [Color(0xFF34d399), Color(0xFF14b8a6)],
    ),
    'intermediate': (
      label: 'Intermediate',
      colors: [Color(0xFF60a5fa), Color(0xFF6366f1)],
    ),
    'advanced': (
      label: 'Advanced',
      colors: [Color(0xFFfb7185), Color(0xFFec4899)],
    ),
  };

  static const _defaultTagColors = [Color(0xFFfbbf24), Color(0xFFf97316)];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 112),
      color: const Color(0xFFf8fafc).withValues(alpha: 0.5),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Flex(
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
                            color: const Color(0xFFfff1f2),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: const Color(0xFFffe4e6)),
                          ),
                          child: Text(
                            '🔥 Trending Now',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFe11d48),
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
                              const TextSpan(text: 'Top-rated '),
                              WidgetSpan(
                                child: GradientText(
                                  'Courses',
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ScrollButton(
                          icon: Icons.arrow_back,
                          onPressed: () => _scroll(-1),
                          filled: false,
                        ),
                        const SizedBox(width: 12),
                        _ScrollButton(
                          icon: Icons.arrow_forward,
                          onPressed: () => _scroll(1),
                          filled: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 56),

          // Course cards from Firebase
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1280),
                height: 440,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('courses')
                      .where('visibility', isEqualTo: 'published')
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF059669),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      debugPrint('Courses loading error: ${snapshot.error}');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.alertCircle,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to load courses',
                              style: GoogleFonts.inter(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.bookOpen,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Courses coming soon!',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 24),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final courseId = docs[index].id;

                        // Extract fields with fallbacks
                        final title = data['title'] ?? 'Untitled Course';
                        final subtitle = data['subtitle'] ?? '';
                        final thumbnailUrl = data['thumbnailUrl'] ?? '';
                        debugPrint(
                          'Course "$title" thumbnailUrl: "$thumbnailUrl"',
                        );
                        final price =
                            (data['priceDefault'] as num?)?.toDouble() ?? 0.0;
                        final level = (data['level'] as String?) ?? 'beginner';
                        final language = (data['language'] as String?) ?? 'en';
                        final tags = List<String>.from(data['tags'] ?? []);
                        final emoji = data['emoji'] ?? '📚';

                        // Gradient colors
                        List<Color> gradientColors;
                        if (data['gradientColors'] != null) {
                          gradientColors = (data['gradientColors'] as List)
                              .map((c) => Color(c as int))
                              .toList();
                        } else {
                          gradientColors = [
                            const Color(0xFF2196F3),
                            const Color(0xFF1976D2),
                          ];
                        }

                        // Tag style
                        final tagStyle = _tagStyles[level.toLowerCase()];
                        final tagLabel = tags.isNotEmpty
                            ? tags.first
                            : (tagStyle?.label ?? 'Course');
                        final tagColors = tagStyle?.colors ?? _defaultTagColors;

                        return _CourseCard(
                          courseId: courseId,
                          title: title,
                          subtitle: subtitle,
                          thumbnailUrl: thumbnailUrl,
                          price: price,
                          level: level,
                          language: language,
                          tag: tagLabel,
                          tagColors: tagColors,
                          emoji: emoji,
                          gradientColors: gradientColors,
                          delay: index * 80,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  const _ScrollButton({
    required this.icon,
    required this.onPressed,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? const Color(0xFF0f172a) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: filled
                ? null
                : Border.all(color: const Color(0xFFe2e8f0), width: 2),
          ),
          child: Center(
            child: Icon(
              icon,
              color: filled ? Colors.white : const Color(0xFF94a3b8),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatefulWidget {
  final String courseId;
  final String title;
  final String subtitle;
  final String thumbnailUrl;
  final double price;
  final String level;
  final String language;
  final String tag;
  final List<Color> tagColors;
  final String emoji;
  final List<Color> gradientColors;
  final int delay;

  const _CourseCard({
    required this.courseId,
    required this.title,
    required this.subtitle,
    required this.thumbnailUrl,
    required this.price,
    required this.level,
    required this.language,
    required this.tag,
    required this.tagColors,
    required this.emoji,
    required this.gradientColors,
    required this.delay,
  });

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool _isHovered = false;

  String _formatPrice(double price) {
    if (price <= 0) return 'Free';
    return '₹${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  String _capitalizeLevel(String level) {
    if (level.isEmpty) return '';
    return level[0].toUpperCase() + level.substring(1);
  }

  void _handleTap(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Not logged in — go to login first
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      // After returning from login, check again
      final loggedInUser = FirebaseAuth.instance.currentUser;
      if (loggedInUser == null) return; // user didn't log in
    }
    if (!context.mounted) return;

    // Navigate immediately with basic course data — batches load on detail page
    final course = Course(
      id: widget.courseId,
      title: widget.title,
      subtitle: widget.subtitle,
      emoji: widget.emoji,
      gradientColors: widget.gradientColors,
      thumbnailUrl: widget.thumbnailUrl,
      priceDefault: widget.price,
    );

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CourseDetailPage(course: course)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: () => _handleTap(context),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 380,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFf1f5f9)),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? Colors.black.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: _isHovered ? 30 : 10,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail / Gradient Header
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedScale(
                            duration: const Duration(milliseconds: 700),
                            scale: _isHovered ? 1.1 : 1.0,
                            child: widget.thumbnailUrl.isNotEmpty
                                ? Image.network(
                                    widget.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildGradientFallback(),
                                  )
                                : _buildGradientFallback(),
                          ),
                          // Gradient overlay
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Tag
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: widget.tagColors,
                                ),
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.tagColors[0].withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.tag.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Meta row
                        Row(
                          children: [
                            Icon(
                              LucideIcons.graduationCap,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _capitalizeLevel(widget.level),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              LucideIcons.globe,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.language == 'hi'
                                  ? 'Hindi'
                                  : widget.language == 'en'
                                  ? 'English'
                                  : widget.language == 'bilingual'
                                  ? 'Bilingual'
                                  : widget.language.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isHovered
                                ? const Color(0xFF059669)
                                : const Color(0xFF0f172a),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Subtitle
                        if (widget.subtitle.isNotEmpty)
                          Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF94a3b8),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Price row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatPrice(widget.price),
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: widget.price <= 0
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF0f172a),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _isHovered
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFecfdf5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                LucideIcons.arrowRight,
                                size: 20,
                                color: _isHovered
                                    ? Colors.white
                                    : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: widget.delay.ms)
        .slideY(begin: 0.15, end: 0, delay: widget.delay.ms);
  }

  Widget _buildGradientFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.gradientColors.length >= 2
              ? widget.gradientColors
              : [const Color(0xFF2196F3), const Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(widget.emoji, style: const TextStyle(fontSize: 56)),
      ),
    );
  }
}
