import 'package:flutter/material.dart';
import '../theme/academic_futurist_theme.dart';

class FeaturedProgramsSection extends StatelessWidget {
  final VoidCallback? onViewAll;
  final void Function(String programName)? onProgramSelected;

  const FeaturedProgramsSection({
    super.key,
    this.onViewAll,
    this.onProgramSelected,
  });

  static const List<_ProgramData> _programs = [
    _ProgramData(
      title: 'UPSC Preparation',
      category: 'UPSC',
      categoryColor: EduverseTheme.secondary,
      description:
          'Master the civil services exam with comprehensive video lectures, secure PDF notes, and rigorous test series.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCzj92Ts8iGEgIT2XYOsMwGXnv1QMD3anPSUEvVFKBdztvmYGpUh-CqC6f0NVbAwRiI53r6akkaPmBJY0aYk1mYFVDFqjllDyVXqjvw53F6GURsUEks0D_weSHTHVqA9P34DUnM8OlknjRFBvdqLjuLi049LMBf0JjbjXd7L9u10CzWoHduINfxTbNMZuynJHRyzkFx6l6vXZCtM-vdN5gWtWO7HruL4L_O4EbaySyAJKbu9Ig8ljoS',
      desktopTopOffset: 0.0,
    ),
    _ProgramData(
      title: 'State PSC Mastery',
      category: 'State PSC',
      categoryColor: EduverseTheme.tertiaryContainer,
      description:
          'State-specific curriculum designed by top educators. Includes live classes with timetable and community discussions.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBlDxC6tGVvL08e_nyMeybi8yE4WODrLwzMAdNdh-HKrGxxUOyeOh056TNZ5GJaMwJL0OWbMaCgtG4LtvkiRru45fo3VOnG0e3DK9pBmPd9awUe672V2FUF6q8KZb_cfGEd4VvFMUmvpt7HYOCG5yAfnXqJ9R24TFbuS9vyYyKPCUG96X-MvvBJwnSIGL2A0EprksyW6iFbQ23B36oUWrVLYcLNhdpzTOZhoShYyw32Iz5BFrvAoNhp',
      desktopTopOffset: 24.0,
    ),
    _ProgramData(
      title: 'SSC & Banking',
      category: 'Banking',
      categoryColor: EduverseTheme.primary,
      description:
          'Aces your SSC and Banking exams with our targeted study materials, test series with analytics, and expert guidance.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBfSIciVx_JOXNopo1W_hJZoiC1yNNEz2-HeWYwzTnhyaM7jLjyShDlE8g9DBI0Ia_8kNlK8rhZjyJc91v84oV0_XwiALuYFMuyEPLSu8Nk8WmJtyihpOQgjLM0OC47E9H_xCuWRQ8OP-tlgGA7a7MODaKV8WnrirC0LIahW2J2TixLHBtjlOprdc5FLJVfIZbN6EQu4wWA5kj2swgko7bTIYH5lde7521YVK-yfg1wnMKCeXh-476W',
      desktopTopOffset: 48.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 640 && screenWidth < 1024;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: EduverseTheme.containerMax),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? EduverseTheme.marginDesktop : EduverseTheme.marginMobile,
          vertical: EduverseTheme.sectionGap,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Flex(
              direction: isDesktop ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment:
                  isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRICULUM',
                      style: EduverseTheme.labelSm(
                        color: EduverseTheme.tertiaryContainer,
                        letterSpacing: 2.0,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Featured Programs',
                      style: EduverseTheme.headlineLg(color: EduverseTheme.onSurface),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: Text(
                        'Discover our most sought-after academic tracks designed for competitive exam success.',
                        style: EduverseTheme.bodyMd(color: EduverseTheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                if (!isDesktop) const SizedBox(height: 16),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onViewAll,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All Programs',
                          style: EduverseTheme.labelLg(color: EduverseTheme.primary).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: EduverseTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Programs Grid / Wrap
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _programs.map((program) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Transform.translate(
                        offset: Offset(0, program.desktopTopOffset),
                        child: _ProgramCard(
                          program: program,
                          onTap: () => onProgramSelected?.call(program.title),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )
            else if (isTablet)
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: _programs.map((program) {
                  return SizedBox(
                    width: (screenWidth - (EduverseTheme.marginMobile * 2) - 24) / 2,
                    child: _ProgramCard(
                      program: program,
                      onTap: () => onProgramSelected?.call(program.title),
                    ),
                  );
                }).toList(),
              )
            else
              Column(
                children: _programs.map((program) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _ProgramCard(
                      program: program,
                      onTap: () => onProgramSelected?.call(program.title),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgramData {
  final String title;
  final String category;
  final Color categoryColor;
  final String description;
  final String imageUrl;
  final double desktopTopOffset;

  const _ProgramData({
    required this.title,
    required this.category,
    required this.categoryColor,
    required this.description,
    required this.imageUrl,
    required this.desktopTopOffset,
  });
}

class _ProgramCard extends StatefulWidget {
  final _ProgramData program;
  final VoidCallback? onTap;

  const _ProgramCard({required this.program, this.onTap});

  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<_ProgramCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.program;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
          decoration: BoxDecoration(
            color: EduverseTheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? EduverseTheme.primary.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isHovered ? 24 : 12,
                offset: Offset(0, _isHovered ? 8 : 3),
              ),
            ],
            border: Border.all(
              color: EduverseTheme.outlineVariant.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Thumbnail with Category Badge
                Stack(
                  children: [
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Image.network(
                        p.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: EduverseTheme.surfaceContainerLow,
                          child: const Icon(Icons.school, size: 48, color: EduverseTheme.primary),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: EduverseTheme.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          p.category,
                          style: EduverseTheme.labelSm(
                            color: p.categoryColor,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),

                // Card Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: EduverseTheme.headlineMd(
                          color: _isHovered ? EduverseTheme.primary : EduverseTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        p.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: EduverseTheme.bodyMd(color: EduverseTheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: EduverseTheme.outlineVariant.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 18,
                                  color: EduverseTheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Live Classes',
                                  style: EduverseTheme.labelSm(
                                    color: EduverseTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Learn More',
                              style: EduverseTheme.labelLg(color: EduverseTheme.primary).copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
