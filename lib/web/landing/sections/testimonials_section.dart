import 'package:flutter/material.dart';
import '../theme/academic_futurist_theme.dart';

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  static const List<_TestimonialData> _testimonials = [
    _TestimonialData(
      quote:
          '"The UPSC Preparation program completely transformed my study routine. The secure notes and live classes were invaluable, leading directly to my success in the prelims."',
      name: 'Sarah Jenkins',
      role: 'Alumna, Class of 2023',
      avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCoi7VbdfrBlQGMu7pLgtGEIDgmci4VEhy606U9hLrtItF4nqATB40OmkSi3D5YxhoVokhuBBvsu_pqSvzatm-zOfQC256pNN8qKlSVAtfexZB7ORowtRhseBhqy0YwOOgPxuBfeWtiFYpynzEPqdyxP5_EmKLK0SeUAOmKgucUou9dhvkh9TJUHa01m4K1VF6FAVGH1Ij8WIUHH93TzLcsp-JAJYgD7BHE6YxpbxUowrBZv4zGT-KU',
      accentColor: EduverseTheme.primary,
    ),
    _TestimonialData(
      quote:
          '"I appreciated the detailed analytics in the SSC test series. The ability to identify my weak spots provided insights you simply cannot get from a textbook."',
      name: 'David Chen',
      role: 'SSC Aspirant',
      avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuATDLo6Z8Kji5WqBPkApgghQiO3R-xjDEF5Yh-tCQk-tl4VCRcwgNrSqhQlfFsHVsWv4tSUyY8Pry1x_EO2pwUXuHzIK9IGwGL6oPYbqF8yuvKTFNmeB5DXARpCZlporqmXRs8eyS0iadf8G2OgNDqBQ_BsSPZMLBnF-CMpVAta4Aq4JI3v5qHFAVxNyDCQNe7JAn2Ir_XNYcFHPPI4YgM_RTzEUckn2Aggv6S1ZvZPJOI0-t_TCP7f',
      accentColor: EduverseTheme.tertiaryContainer,
    ),
    _TestimonialData(
      quote:
          '"The community discussions for State PSC were eye-opening. It gave me practical insights and peer support that kept me motivated throughout my preparation journey."',
      name: 'Elena Rodriguez',
      role: 'State PSC Candidate',
      avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCpa49Xr3CTLJ68dQa-4vgbMRChA8Qz6JI2cqNhf4YoavO6CIELU-K_zT8eZ9ilZwz1yjD0ARP4mqiaLapr0DZWUFmcvvfOHb2G97YbzlLS_eaNs-mOi6cKT4R0xEsBVsC4CZaoZiY4eyyOiYjfLmJxt9u_ik281ojBlztGegKt3_W3wf9na8s9q06jp722p14vVdKwzkQX8x8wOkfkZAlxDlqo6io7TyksCAit2gzGdwqNe9l4yJLw',
      accentColor: EduverseTheme.secondary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Container(
      width: double.infinity,
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
              Text(
                'Student Success Stories',
                style: EduverseTheme.headlineLg(color: EduverseTheme.onSurface),
              ),
              const SizedBox(height: 48),

              // Responsive Cards
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _testimonials.map((t) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _TestimonialCard(testimonial: t),
                      ),
                    );
                  }).toList(),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _testimonials.map((t) {
                      return Container(
                        width: (screenWidth * 0.85).clamp(280.0, 420.0),
                        margin: const EdgeInsets.only(right: 16),
                        child: _TestimonialCard(testimonial: t),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestimonialData {
  final String quote;
  final String name;
  final String role;
  final String avatarUrl;
  final Color accentColor;

  const _TestimonialData({
    required this.quote,
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.accentColor,
  });
}

class _TestimonialCard extends StatelessWidget {
  final _TestimonialData testimonial;

  const _TestimonialCard({required this.testimonial});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: EduverseTheme.outlineVariant.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Quote Mark Watermark
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.format_quote,
              size: 56,
              color: testimonial.accentColor.withValues(alpha: 0.15),
            ),
          ),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                testimonial.quote,
                style: EduverseTheme.bodyLg(color: EduverseTheme.onSurface).copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Image.network(
                        testimonial.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: EduverseTheme.surfaceContainerLow,
                          child: const Icon(Icons.person, color: EduverseTheme.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testimonial.name,
                        style: EduverseTheme.labelLg(color: EduverseTheme.onSurface).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        testimonial.role,
                        style: EduverseTheme.labelSm(color: EduverseTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
